# TODO: Implement this module.
# Read the README.md in this directory for the full list of resources to create.
# Refer to the Terraform documentation: https://registry.terraform.io/providers/hashicorp/aws/latest/docs

resource "aws_db_subnet_group" "main" {
  name       = "lks-subnet-rds"
  subnet_ids = var.isolated_subnet_ids

  tags = {
    Name = "lks-subnet-rds"
  }
}

resource "aws_db_instance" "main" {
  identifier           = "lks-rds-postgres"
  allocated_storage    = 20
  db_name              = var.db_name
  engine               = "postgres"
  engine_version       = "15"
  instance_class       = var.db_instance_class
  username             = var.db_username
  password             = var.db_password
  publicly_accessible  = false
  skip_final_snapshot  = true
  backup_retention_period = 7
  vpc_security_group_ids = [var.security_group_id]
  db_subnet_group_name = aws_db_subnet_group.main.id
}

resource "aws_dynamodb_table" "main" {
  name           = var.dynamo_table
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "sessionId"
  range_key      = "createdAt"

  attribute {
    name = "sessionId"
    type = "S"
  }

  attribute {
    name = "createdAt"
    type = "N"
  }

  ttl {
    attribute_name = "expiresAt"
    enabled        = true
  }

  point_in_time_recovery {
    enabled = true
  }
}

resource "aws_sqs_queue" "main" {
  name                      = var.sqs_queue_name
  visibility_timeout_seconds = 30
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 3
  })
}

resource "aws_sqs_queue" "dlq" {
  name                      = var.dlq_name
}

resource "aws_sqs_queue_redrive_allow_policy" "dlq" {
  queue_url = aws_sqs_queue.dlq.id

  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue",
    sourceQueueArns   = [aws_sqs_queue.main.arn]
  })
}

resource "aws_ssm_parameter" "db_host" {
  name  = "/lks/app/db_host"
  type  = "SecureString"
  value = aws_db_instance.main.address
}

resource "aws_ssm_parameter" "db_password" {
  name  = "/lks/app/db_password"
  type  = "SecureString"
  value = var.db_password

  depends_on = [aws_db_instance.main]
}

resource "aws_ssm_parameter" "sqs_url" {
  name  = "/lks/app/sqs_url"
  type  = "String"
  value = aws_sqs_queue.main.url

  depends_on = [aws_db_instance.main]
}

resource "aws_ssm_parameter" "dynamodb_table" {
  name  = "/lks/app/dynamodb_table"
  type  = "String"
  value = var.dynamo_table

  depends_on = [aws_db_instance.main]
}

resource "aws_cloudwatch_log_group" "fe" {
  name = "/ecs/lks-fe-app"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "api" {
  name = "/ecs/lks-api-app"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "analytics" {
  name = "/ecs/lks-analytics-app"
  retention_in_days = 7
}

provider "aws" {
    alias  = "oregon"
    region = "us-west-2"
}

resource "aws_cloudwatch_log_group" "prometheus" {
  provider = aws.oregon
  name = "/ecs/lks-prometheus"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "grafana" {
  provider = aws.oregon
  name = "/ecs/lks-grafana"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "loki" {
  provider = aws.oregon
  name = "/ecs/lks-loki"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "alertmanager" {
  provider = aws.oregon
  name = "/ecs/lks-alertmanager"
  retention_in_days = 7
}

resource "aws_sns_topic" "main" {
  name = "lks-alerts"
}

resource "aws_sns_topic_subscription" "main" {
  topic_arn = aws_sns_topic.main.arn
  protocol  = "email"
  endpoint  = "riiyfahr1@gmail.com"
}