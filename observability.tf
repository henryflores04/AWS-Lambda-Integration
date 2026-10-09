
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

resource "aws_cloudwatch_log_group" "apigw" {
  name              = "/aws/apigateway/${local.name_prefix}-api"
  retention_in_days = var.log_retention_days

  tags = {
    Name = "/aws/apigateway/${local.name_prefix}-api"
  }
}

resource "aws_sns_topic" "dlq_alarm" {
  name = "${local.name_prefix}-dlq-alarm"

  tags = {
    Name = "${local.name_prefix}-dlq-alarm"
  }
}

resource "aws_sns_topic_subscription" "dlq_alarm_email" {
  count = var.alarm_email != "" ? 1 : 0

  topic_arn = aws_sns_topic.dlq_alarm.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

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

  alarm_actions = var.alarm_email != "" ? [aws_sns_topic.dlq_alarm.arn] : []

  tags = {
    Name = "${local.name_prefix}-dlq-messages-alarm"
  }
}
