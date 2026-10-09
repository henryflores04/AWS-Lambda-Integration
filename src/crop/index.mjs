import { S3Client, GetObjectCommand, PutObjectCommand } from "@aws-sdk/client-s3";
import sharp from "sharp";

const s3 = new S3Client({});

const BUCKET = process.env.S3_BUCKET;
const PROCESSED_PREFIX = process.env.PROCESSED_PREFIX || "processed/";
const SIZE = 40; // 40x40 px, lo que exige el diagrama

export const handler = async (event) => {
  console.log(`Batch de ${event.Records.length} mensaje(s)`);

  const batchItemFailures = [];

  for (const record of event.Records) {
    try {
      await processRecord(record);
    } catch (error) {
      // Logueamos el error y marcamos SOLO este mensaje como fallido.
      // Con ReportBatchItemFailures, SQS reintenta únicamente el que falló,
      // no los 5 del batch. Los ya procesados no se duplican.
      console.error(`Falló el mensaje ${record.messageId}:`, error);
      batchItemFailures.push({ itemIdentifier: record.messageId });
    }
  }

  console.log(`Fallidos: ${batchItemFailures.length} de ${event.Records.length}`);
  return { batchItemFailures };
};

async function processRecord(record) {
  // El body trae la notificación de S3 dentro de Records[]
  const body = JSON.parse(record.body);
  const s3Event = body.Records?.[0];

  if (!s3Event?.s3) {
    throw new Error("El mensaje no contiene una notificación de S3 válida.");
  }

  // OJO: la key viene URL-encoded (los espacios llegan como "+")
  const key = decodeURIComponent(s3Event.s3.object.key.replace(/\+/g, " "));
  const bucket = s3Event.s3.bucket.name;

  console.log(`Procesando s3://${bucket}/${key}`);

  // 1. Descargar el original (viaja por el S3 Gateway Endpoint)
  const original = await s3.send(
    new GetObjectCommand({ Bucket: bucket, Key: key })
  );
  const inputBuffer = Buffer.from(await original.Body.transformToByteArray());

  console.log(`Original: ${inputBuffer.length} bytes`);

  // 2. Recorte circular 40x40 con alpha transparente
  const outputBuffer = await makeCircular(inputBuffer);

  // 3. Construir el nombre de salida: "foto.jpg" -> "foto_circular.png"
  const baseName = key.split("/").pop().replace(/\.[^.]+$/, "");
  const outputKey = `${PROCESSED_PREFIX}${baseName}_circular.png`;

  // 4. Subir el resultado
  await s3.send(
    new PutObjectCommand({
      Bucket: bucket,
      Key: outputKey,
      Body: outputBuffer,
      ContentType: "image/png",
    })
  );

  console.log(`Generado: s3://${bucket}/${outputKey}`);
}

/**
 * Recorta la imagen a un círculo de 40x40 con fondo transparente.
 *
 * Usamos una máscara generada por código en vez de un SVG, para no
 * depender del parser XML de sharp en el runtime de Lambda.
 *
 * El cálculo del alpha por distancia al centro es lo que da el
 * anti-aliasing: los píxeles del borde quedan semitransparentes en
 * lugar de escalonados.
 */
async function makeCircular(inputBuffer) {
  const radius = SIZE / 2;
  const mask = Buffer.alloc(SIZE * SIZE * 4);

  for (let y = 0; y < SIZE; y++) {
    for (let x = 0; x < SIZE; x++) {
      const dx = x + 0.5 - radius;
      const dy = y + 0.5 - radius;
      const distance = Math.sqrt(dx * dx + dy * dy);

      // 1 dentro del círculo, 0 fuera, degradado en el borde (anti-aliasing)
      let alpha = radius - distance + 0.5;
      alpha = Math.max(0, Math.min(1, alpha));

      const i = (y * SIZE + x) * 4;
      mask[i] = 255;     // R
      mask[i + 1] = 255; // G
      mask[i + 2] = 255; // B
      mask[i + 3] = Math.round(alpha * 255);
    }
  }

  return sharp(inputBuffer)
    .resize(SIZE, SIZE, { fit: "cover", position: "centre" })
    .ensureAlpha()
    .composite([
      {
        input: mask,
        raw: { width: SIZE, height: SIZE, channels: 4 },
        blend: "dest-in",
      },
    ])
    .png()
    .toBuffer();
}