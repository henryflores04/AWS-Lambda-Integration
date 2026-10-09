data "archive_file" "upload_zip" {
  type        = "zip"
  source_dir  = "${path.module}/src/upload"
  output_path = "${path.module}/build/upload.zip"
  excludes    = ["Dockerfile", ".dockerignore"]
}

data "archive_file" "crop_zip" {
  type        = "zip"
  source_dir  = "${path.module}/src/crop"
  output_path = "${path.module}/build/crop.zip"
  excludes    = ["Dockerfile", ".dockerignore"]
}

resource "aws_lambda_function" "upload" {
  function_name = local.upload_lambda_name
  role          = aws_iam_role.upload_lambda.arn
  handler       = "index.handler"
  runtime       = var.lambda_runtime
  memory_size   = var.lambda_upload_memory_mb
  timeout       = var.lambda_upload_timeout_s
  architectures = ["x86_64"]

  filename         = data.archive_file.upload_zip.output_path
  source_code_hash = data.archive_file.upload_zip.output_base64sha256

  environment {
    variables = {
      S3_BUCKET     = aws_s3_bucket.images.id
      UPLOAD_PREFIX = local.upload_prefix
    }
  }

  vpc_config {
    subnet_ids         = aws_subnet.private[*].id
    security_group_ids = [aws_security_group.lambda_upload.id]
  }

  tags = {
    Name = local.upload_lambda_name
  }

  depends_on = [aws_cloudwatch_log_group.upload_lambda]
}

resource "aws_lambda_function" "crop" {
  function_name = local.crop_lambda_name
  role          = aws_iam_role.crop_lambda.arn
  handler       = "index.handler"
  runtime       = var.lambda_runtime
  memory_size   = var.lambda_crop_memory_mb
  timeout       = var.lambda_crop_timeout_s
  architectures = ["x86_64"]

  filename         = data.archive_file.crop_zip.output_path
  source_code_hash = data.archive_file.crop_zip.output_base64sha256

  environment {
    variables = {
      S3_BUCKET        = aws_s3_bucket.images.id
      PROCESSED_PREFIX = local.processed_prefix
    }
  }

  vpc_config {
    subnet_ids         = aws_subnet.private[*].id
    security_group_ids = [aws_security_group.lambda_crop.id]
  }

  tags = {
    Name = local.crop_lambda_name
  }

  depends_on = [aws_cloudwatch_log_group.crop_lambda]
}

resource "aws_s3_bucket_notification" "images" {
  bucket = aws_s3_bucket.images.id

  queue {
    id            = "uploads-object-created"
    queue_arn     = aws_sqs_queue.main.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = local.upload_prefix
  }

  depends_on = [aws_sqs_queue_policy.main]
}

resource "aws_lambda_event_source_mapping" "crop" {
  event_source_arn = aws_sqs_queue.main.arn
  function_name    = aws_lambda_function.crop.arn
  batch_size       = 5

  function_response_types = ["ReportBatchItemFailures"]

  scaling_config {
    maximum_concurrency = 2
  }
}
