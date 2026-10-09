resource "aws_sqs_queue" "dlq" {
  name                       = local.dlq_name
  message_retention_seconds  = 1209600
  visibility_timeout_seconds = 360
  sqs_managed_sse_enabled    = true

  tags = {
    Name = local.dlq_name
    Role = "dead-letter"
  }
}

resource "aws_sqs_queue" "main" {
  name                       = local.main_queue_name
  visibility_timeout_seconds = 360
  message_retention_seconds  = var.sqs_message_retention_seconds
  receive_wait_time_seconds  = 20
  sqs_managed_sse_enabled    = true

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 3
  })

  tags = {
    Name = local.main_queue_name
    Role = "main"
  }
}

resource "aws_sqs_queue_policy" "main" {
  queue_url = aws_sqs_queue.main.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowS3BucketNotifications"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.main.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_s3_bucket.images.arn
          }
        }
      }
    ]
  })
}
