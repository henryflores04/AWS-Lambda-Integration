resource "aws_security_group" "lambda_upload" {
  name_prefix = "${local.upload_lambda_name}-"
  description = "SG de upload-lambda: sin inbound, outbound 443 hacia los VPC endpoints"
  vpc_id      = aws_vpc.this.id

  tags = {
    Name = "${local.upload_lambda_name}-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_egress_rule" "upload_https" {
  security_group_id = aws_security_group.lambda_upload.id
  description       = "HTTPS saliente hacia S3 y servicios de AWS"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_security_group" "lambda_crop" {
  name_prefix = "${local.crop_lambda_name}-"
  description = "SG de crop-lambda: sin inbound, outbound 443 hacia los VPC endpoints"
  vpc_id      = aws_vpc.this.id

  tags = {
    Name = "${local.crop_lambda_name}-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_egress_rule" "crop_https" {
  security_group_id = aws_security_group.lambda_crop.id
  description       = "HTTPS saliente hacia S3, SQS y servicios de AWS"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_security_group" "vpce_sqs" {
  name_prefix = "${local.name_prefix}-vpce-sqs-"
  description = "SG del SQS Interface Endpoint: inbound 443 desde las Lambdas"
  vpc_id      = aws_vpc.this.id

  tags = {
    Name = "${local.name_prefix}-sg-vpce-sqs"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "vpce_sqs_from_upload" {
  security_group_id            = aws_security_group.vpce_sqs.id
  description                  = "HTTPS desde upload-lambda"
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  referenced_security_group_id = aws_security_group.lambda_upload.id
}

resource "aws_vpc_security_group_ingress_rule" "vpce_sqs_from_crop" {
  security_group_id            = aws_security_group.vpce_sqs.id
  description                  = "HTTPS desde crop-lambda"
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  referenced_security_group_id = aws_security_group.lambda_crop.id
}
