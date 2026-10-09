# ── Log groups de Lambda ───────────────────────────────────────────────
# Se crean explicitamente para controlar la retencion (14 dias).
# Si no existieran, Lambda los crearia solo y con retencion INFINITA.
resource "aws_cloudwatch_log_group" "upload_lambda" {
  name              = "/aws/lambda/${local.upload_lambda_name}"
  retention_in_days = var.log_retention_days

  tags = {
    Name = "/aws/lambda/${local.upload_lambda_name}"
  }
}

resource "aws_cloudwatch_log_group" "crop_lambda" {
  name              = "/aws/lambda/${local.crop_lambda_name}"
  retention_in_days = var.log_retention_days

  tags = {
    Name = "/aws/lambda/${local.crop_lambda_name}"
  }
}

# ── Log group de API Gateway ───────────────────────────────────────────
# Destino de los access logs JSON configurados en api.tf.
resource "aws_cloudwatch_log_group" "apigw" {
  name              = "/aws/apigateway/${local.name_prefix}-api"
  retention_in_days = var.log_retention_days

  tags = {
    Name = "/aws/apigateway/${local.name_prefix}-api"
  }
}

# ── Topic SNS para la alarma de la DLQ ─────────────────────────────────
# El diagrama dice "Action: notify via SNS topic" pero NO dibuja el topic.
# Este es el hueco #1 que identificamos al inicio: hay que crearlo.
resource "aws_sns_topic" "dlq_alarm" {
  name = "${local.name_prefix}-dlq-alarm"

  tags = {
    Name = "${local.name_prefix}-dlq-alarm"
  }
}

# Suscripcion por correo. OJO: AWS envia un correo de confirmacion y la
# suscripcion queda en estado "PendingConfirmation" hasta que se confirme.
# Debes declarar alarm_email en tu tfvars para que esto haga algo util.
resource "aws_sns_topic_subscription" "dlq_alarm_email" {
  count = var.alarm_email != "" ? 1 : 0

  topic_arn = aws_sns_topic.dlq_alarm.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

# ── Alarma: cualquier mensaje visible en la DLQ ────────────────────────
# Metric: ApproximateNumberOfMessagesVisible > 0 en 1 periodo de 60s.
resource "aws_cloudwatch_metric_alarm" "dlq_messages" {
  alarm_name          = "${local.name_prefix}-dlq-messages-alarm"
  alarm_description   = "Hay mensajes en la DLQ: crop-lambda fallo 3 veces con ellos"
  namespace           = "AWS/SQS"
  metric_name         = "ApproximateNumberOfMessagesVisible"
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    QueueName = aws_sqs_queue.dlq.name
  }

  # Solo adjunta la accion si hay un correo configurado.
  alarm_actions = var.alarm_email != "" ? [aws_sns_topic.dlq_alarm.arn] : []

  tags = {
    Name = "${local.name_prefix}-dlq-messages-alarm"
  }
}

# ── Nota sobre el orden de creacion ────────────────────────────────────
# Terraform podria crear la Lambda ANTES que su log group, porque la
# Lambda no referencia el log group. Si eso pasa, Lambda crea el log group
# primero, con retencion infinita, y el aws_cloudwatch_log_group despues
# NO puede cambiar la retencion de un grupo que no creo (falla con
# ResourceAlreadyExistsException).
#
# Por eso agregamos en lambda.tf:
#   depends_on = [aws_cloudwatch_log_group.upload_lambda]
#   depends_on = [aws_cloudwatch_log_group.crop_lambda]
