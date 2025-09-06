terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# DynamoDB 백업 계획
resource "aws_backup_plan" "dynamodb" {
  name = "${var.project_name}-dynamodb-backup"

  rule {
    rule_name         = "daily_backup"
    target_vault_name = aws_backup_vault.main.name
    schedule          = "cron(0 2 * * ? *)" # 매일 오전 2시

    lifecycle {
      cold_storage_after = 30
      delete_after       = 365
    }

    recovery_point_tags = {
      Environment = var.environment
      BackupType  = "Daily"
    }
  }

  rule {
    rule_name         = "weekly_backup"
    target_vault_name = aws_backup_vault.main.name
    schedule          = "cron(0 3 ? * SUN *)" # 매주 일요일 오전 3시

    lifecycle {
      cold_storage_after = 7
      delete_after       = 2555 # 7년
    }

    recovery_point_tags = {
      Environment = var.environment
      BackupType  = "Weekly"
    }
  }
}

# 백업 볼트
resource "aws_backup_vault" "main" {
  name        = "${var.project_name}-backup-vault"
  kms_key_arn = aws_kms_key.backup.arn

  tags = {
    Name = "${var.project_name}-backup-vault"
  }
}

# 백업용 KMS 키
resource "aws_kms_key" "backup" {
  description             = "${var.project_name} backup encryption key"
  deletion_window_in_days = 7

  tags = {
    Name = "${var.project_name}-backup-key"
  }
}

resource "aws_kms_alias" "backup" {
  name          = "alias/${var.project_name}-backup"
  target_key_id = aws_kms_key.backup.key_id
}

# 백업 IAM 역할
resource "aws_iam_role" "backup" {
  name = "${var.project_name}-backup-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "backup.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "backup" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

# DynamoDB 테이블 백업 선택
resource "aws_backup_selection" "dynamodb" {
  iam_role_arn = aws_iam_role.backup.arn
  name         = "${var.project_name}-dynamodb-selection"
  plan_id      = aws_backup_plan.dynamodb.id

  resources = [
    "arn:aws:dynamodb:${var.aws_region}:*:table/LiveInsight-Events",
    "arn:aws:dynamodb:${var.aws_region}:*:table/LiveInsight-Sessions",
    "arn:aws:dynamodb:${var.aws_region}:*:table/LiveInsight-ActiveSessions"
  ]
}

# S3 버킷 백업 (정적 자산)
data "aws_s3_bucket" "static_assets" {
  bucket = "${var.project_name}-static-assets-*"
}

resource "aws_s3_bucket_versioning" "static_assets" {
  bucket = data.aws_s3_bucket.static_assets.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "static_assets" {
  bucket = data.aws_s3_bucket.static_assets.id

  rule {
    id     = "backup_lifecycle"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 90
    }

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }

    noncurrent_version_transition {
      noncurrent_days = 60
      storage_class   = "GLACIER"
    }
  }
}

# 백업 모니터링
resource "aws_cloudwatch_metric_alarm" "backup_failed" {
  alarm_name          = "${var.project_name}-backup-failed"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "NumberOfBackupJobsFailed"
  namespace           = "AWS/Backup"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "Backup job failed"

  dimensions = {
    BackupVaultName = aws_backup_vault.main.name
  }

  tags = {
    Name = "${var.project_name}-backup-alarm"
  }
}

# 백업 복원 테스트 Lambda
resource "aws_lambda_function" "backup_test" {
  filename         = "backup_test.zip"
  function_name    = "${var.project_name}-backup-test"
  role            = aws_iam_role.backup_test_lambda.arn
  handler         = "index.handler"
  runtime         = "python3.11"
  timeout         = 300

  environment {
    variables = {
      BACKUP_VAULT_NAME = aws_backup_vault.main.name
      PROJECT_NAME      = var.project_name
    }
  }
}

resource "aws_iam_role" "backup_test_lambda" {
  name = "${var.project_name}-backup-test-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "backup_test_lambda" {
  name = "${var.project_name}-backup-test-lambda-policy"
  role = aws_iam_role.backup_test_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "backup:ListRecoveryPoints",
          "backup:DescribeBackupJob",
          "backup:StartRestoreJob",
          "dynamodb:DescribeTable"
        ]
        Resource = "*"
      }
    ]
  })
}

# 월간 백업 테스트 스케줄
resource "aws_cloudwatch_event_rule" "backup_test" {
  name                = "${var.project_name}-backup-test"
  description         = "Monthly backup restore test"
  schedule_expression = "cron(0 4 1 * ? *)" # 매월 1일 오전 4시
}

resource "aws_cloudwatch_event_target" "backup_test" {
  rule      = aws_cloudwatch_event_rule.backup_test.name
  target_id = "BackupTestTarget"
  arn       = aws_lambda_function.backup_test.arn
}

resource "aws_lambda_permission" "backup_test" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.backup_test.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.backup_test.arn
}