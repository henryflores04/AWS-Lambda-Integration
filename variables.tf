# ── Identidad y entorno ────────────────────────────────────────────────
variable "aws_region" {
  description = "Región AWS donde se despliega el entorno"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefijo base para nombrar todos los recursos"
  type        = string
  default     = "image-processor"
}

variable "environment" {
  description = "Entorno lógico. Debe coincidir con el workspace activo"
  type        = string

  validation {
    condition     = contains(["dev", "qa", "prod"], var.environment)
    error_message = "El entorno debe ser exactamente: dev, qa o prod (minúsculas, sin tildes)."
  }
}

# ── Red ────────────────────────────────────────────────────────────────
variable "vpc_cidr" {
  description = "CIDR de la VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDRs de las subredes públicas, en orden AZ-a, AZ-b"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDRs de las subredes privadas, en orden AZ-a, AZ-b"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "nat_gateway_count" {
  description = "Cantidad de NAT Gateway. 2 = alta disponibilidad (diagrama), 1 = mínimo costo, 0 = sin salida a internet"
  type        = number

  validation {
    condition     = contains([0, 1, 2], var.nat_gateway_count)
    error_message = "nat_gateway_count solo acepta 0, 1 o 2."
  }
}

# ── Retención y ciclo de vida ──────────────────────────────────────────
variable "log_retention_days" {
  description = "Retención de los log groups de CloudWatch"
  type        = number
}

variable "uploads_expiration_days" {
  description = "Días antes de expirar objetos del prefijo uploads/"
  type        = number
  default     = 30
}

variable "processed_expiration_days" {
  description = "Días antes de expirar objetos del prefijo processed/"
  type        = number
  default     = 90
}

variable "sqs_message_retention_seconds" {
  description = "Retención de mensajes en la cola principal"
  type        = number
  default     = 86400
}

# ── Lambda ─────────────────────────────────────────────────────────────
variable "lambda_runtime" {
  description = "Runtime de las funciones Lambda"
  type        = string
  default     = "nodejs20.x"
}

variable "lambda_upload_memory_mb" {
  description = "Memoria de upload-lambda en MB"
  type        = number
  default     = 256
}

variable "lambda_upload_timeout_s" {
  description = "Timeout de upload-lambda en segundos"
  type        = number
  default     = 30
}

variable "lambda_crop_memory_mb" {
  description = "Memoria de crop-lambda en MB"
  type        = number
  default     = 512
}

variable "lambda_crop_timeout_s" {
  description = "Timeout de crop-lambda en segundos"
  type        = number
  default     = 60
}

# ── API Gateway ────────────────────────────────────────────────────────
variable "throttling_rate_limit" {
  description = "Límite de requests por segundo del stage"
  type        = number
  default     = 10000
}

variable "cors_allowed_origins" {
  description = "Orígenes permitidos por CORS"
  type        = list(string)
  default     = ["*"]
}

# ── Protección y destrucción ───────────────────────────────────────────
variable "force_destroy_bucket" {
  description = "Permite borrar el bucket con objetos dentro. true en dev/qa, false en prod"
  type        = bool
}

variable "deletion_protection" {
  description = "Bloquea el borrado accidental de recursos críticos"
  type        = bool
}

# ── Alarmas ────────────────────────────────────────────────────────────
variable "alarm_email" {
  description = "Correo que recibe las notificaciones del topic SNS de la alarma DLQ"
  type        = string
  default     = ""
}
