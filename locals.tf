locals {
  # ── Tabla de configuración por entorno ───────────────────────────────
  # Única fuente de verdad. Cambiar un valor aquí cambia el entorno completo.
  env_table = {
    dev = {
      nat_gateway_count    = 1
      log_retention_days   = 7
      force_destroy_bucket = true
      deletion_protection  = false
      sns_alarm_enabled    = false
    }
    qa = {
      nat_gateway_count    = 1
      log_retention_days   = 14
      force_destroy_bucket = true
      deletion_protection  = false
      sns_alarm_enabled    = true
    }
    prod = {
      nat_gateway_count    = 2
      log_retention_days   = 14
      force_destroy_bucket = false
      deletion_protection  = true
      sns_alarm_enabled    = true
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
