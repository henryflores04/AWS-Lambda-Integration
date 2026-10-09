# ── Identidad del entorno ──────────────────────────────────────────────
output "environment" {
  description = "Entorno desplegado (workspace de Terraform)"
  value       = terraform.workspace
}

output "aws_region" {
  description = "Region del despliegue"
  value       = var.aws_region
}

output "aws_account_id" {
  description = "Account ID de AWS donde se desplego. Evidencia para el PDF."
  value       = data.aws_caller_identity.current.account_id
}

# ── URL del proyecto (va en el README) ─────────────────────────────────
output "api_invoke_url" {
  description = "URL para invocar POST /upload. Esta es la URL del proyecto."
  value       = "${aws_apigatewayv2_stage.this.invoke_url}/upload"
}

output "api_id" {
  description = "ID del HTTP API"
  value       = aws_apigatewayv2_api.this.id
}

# ── Almacenamiento ─────────────────────────────────────────────────────
output "bucket_name" {
  description = "Nombre del bucket S3 de imagenes"
  value       = aws_s3_bucket.images.id
}

output "bucket_arn" {
  description = "ARN del bucket S3"
  value       = aws_s3_bucket.images.arn
}

# ── Mensajeria ─────────────────────────────────────────────────────────
output "main_queue_url" {
  description = "URL de la cola principal"
  value       = aws_sqs_queue.main.id
}

output "main_queue_arn" {
  description = "ARN de la cola principal"
  value       = aws_sqs_queue.main.arn
}

output "dlq_url" {
  description = "URL de la dead-letter queue"
  value       = aws_sqs_queue.dlq.id
}

# ── Computo ────────────────────────────────────────────────────────────
output "upload_lambda_name" {
  description = "Nombre de upload-lambda"
  value       = aws_lambda_function.upload.function_name
}

output "crop_lambda_name" {
  description = "Nombre de crop-lambda"
  value       = aws_lambda_function.crop.function_name
}

# ── Red ────────────────────────────────────────────────────────────────
output "vpc_id" {
  description = "ID de la VPC"
  value       = aws_vpc.this.id
}

output "private_subnet_ids" {
  description = "IDs de las subredes privadas donde viven las Lambdas"
  value       = aws_subnet.private[*].id
}

# ── Instrucciones de prueba (aparecen al terminar el apply) ────────────
output "test_command" {
  description = "Comando listo para probar la subida"
  value       = <<-EOT
    curl -X POST "${aws_apigatewayv2_stage.this.invoke_url}/upload" \
      -H "Content-Type: application/json" \
      -d '{"filename":"prueba.png","contentType":"image/png","data":"'$(base64 -w0 prueba.png)'"}'
  EOT
}
