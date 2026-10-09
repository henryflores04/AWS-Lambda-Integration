import { S3Client, PutObjectCommand } from "@aws-sdk/client-s3";
import { randomUUID } from "node:crypto";

const s3 = new S3Client({});

const BUCKET = process.env.S3_BUCKET;
const PREFIX = process.env.UPLOAD_PREFIX || "uploads/";

const MAX_BYTES = 10 * 1024 * 1024;
const ALLOWED = {
  "image/jpeg": "jpg",
  "image/jpg": "jpg",
  "image/png": "png",
  "image/gif": "gif",
  "image/webp": "webp",
};

export const handler = async (event) => {
  console.log("Evento recibido:", JSON.stringify(event));

  try {
    const file = parseBody(event);

    if (!file || !file.buffer) {
      return respond(400, {
        error: "No se recibió ningún archivo.",
        hint: "Envía JSON con { filename, contentType, data } donde data es base64.",
      });
    }

    const ext = ALLOWED[file.contentType];
    if (!ext) {
      return respond(400, {
        error: `Tipo no permitido: ${file.contentType}`,
        allowed: Object.keys(ALLOWED),
      });
    }

    // 3. Validar tamaño
    if (file.buffer.length > MAX_BYTES) {
      return respond(413, {
        error: "El archivo supera el máximo de 10 MB.",
        sizeBytes: file.buffer.length,
        maxBytes: MAX_BYTES,
      });
    }

    if (file.buffer.length === 0) {
      return respond(400, { error: "El archivo está vacío." });
    }

    const key = `${PREFIX}${randomUUID()}.${ext}`;

    await s3.send(
      new PutObjectCommand({
        Bucket: BUCKET,
        Key: key,
        Body: file.buffer,
        ContentType: file.contentType,
      })
    );

    console.log(`Subido: s3://${BUCKET}/${key} (${file.buffer.length} bytes)`);

    return respond(200, {
      message: "Archivo subido correctamente. El procesamiento es asíncrono.",
      bucket: BUCKET,
      key,
      sizeBytes: file.buffer.length,
      contentType: file.contentType,
    });
  } catch (error) {
    console.error("Error en upload-lambda:", error);
    return respond(500, {
      error: "Error interno procesando la subida.",
      detail: error.message,
    });
  }
};

function parseBody(event) {
  let body = event.body;

  if (event.isBase64Encoded && body) {
    body = Buffer.from(body, "base64").toString("utf8");
  }

  if (!body) return null;

  let parsed;
  try {
    parsed = JSON.parse(body);
  } catch {
    return null;
  }

  if (!parsed.data) return null;

  return {
    filename: parsed.filename || "archivo",
    contentType: parsed.contentType || "image/png",
    buffer: Buffer.from(parsed.data, "base64"),
  };
}

function respond(statusCode, payload) {
  return {
    statusCode,
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  };
}