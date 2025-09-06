# S3 버킷 - 정적 파일 저장
resource "aws_s3_bucket" "static_files" {
  bucket = "${lower(var.project_name)}-static-files-${random_id.bucket_suffix.hex}"

  tags = {
    Name        = "${var.project_name}-static-files"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_s3_bucket_versioning" "static_files" {
  bucket = aws_s3_bucket.static_files.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "static_files" {
  bucket = aws_s3_bucket.static_files.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "static_files" {
  bucket = aws_s3_bucket.static_files.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "static_files" {
  bucket = aws_s3_bucket.static_files.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.static_files.arn}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.static_files]
}

# S3 버킷 - ALB 로그 저장
resource "aws_s3_bucket" "alb_logs" {
  bucket = "${lower(var.project_name)}-alb-logs-${random_id.bucket_suffix.hex}"

  tags = {
    Name        = "${var.project_name}-alb-logs"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  rule {
    id     = "delete_old_logs"
    status = "Enabled"

    expiration {
      days = 30
    }
  }
}

resource "aws_s3_bucket_policy" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_elb_service_account.main.id}:root"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.alb_logs.arn}/*"
      }
    ]
  })
}

# S3 버킷 - 백업 저장
resource "aws_s3_bucket" "backups" {
  bucket = "${lower(var.project_name)}-backups-${random_id.bucket_suffix.hex}"

  tags = {
    Name        = "${var.project_name}-backups"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_s3_bucket_versioning" "backups" {
  bucket = aws_s3_bucket.backups.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "backups" {
  bucket = aws_s3_bucket.backups.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "backups" {
  bucket = aws_s3_bucket.backups.id

  rule {
    id     = "backup_lifecycle"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }
  }
}

# 랜덤 ID 생성 (버킷 이름 중복 방지)
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# ELB 서비스 계정 정보
data "aws_elb_service_account" "main" {}

# ECS 태스크에 S3 접근 권한 추가
resource "aws_iam_role_policy" "ecs_task_s3" {
  name = "${var.project_name}-ecs-task-s3"
  role = module.web_app.ecs_task_role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "${aws_s3_bucket.static_files.arn}/*",
          "${aws_s3_bucket.backups.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.static_files.arn,
          aws_s3_bucket.backups.arn
        ]
      }
    ]
  })
}