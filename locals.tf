locals {

  env_table = {
    dev = {
      sns_alarm_enabled = false
    }
    qa = {
      sns_alarm_enabled = true
    }
    prod = {
      sns_alarm_enabled = true
    }
  }

  env = local.env_table[terraform.workspace]

  env_matches_workspace = var.environment == terraform.workspace

  name_prefix = "${var.project_name}-${var.environment}"

  bucket_name = "${local.name_prefix}-images-${random_id.bucket_suffix.hex}"

  upload_lambda_name = "${local.name_prefix}-upload"
  crop_lambda_name   = "${local.name_prefix}-crop"

  main_queue_name = "${local.name_prefix}-image-queue"
  dlq_name        = "${local.name_prefix}-image-dlq"

  upload_prefix    = "uploads/"
  processed_prefix = "processed/"

  az_count = 2
}
