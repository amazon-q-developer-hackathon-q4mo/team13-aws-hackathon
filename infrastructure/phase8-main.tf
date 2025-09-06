# Phase 8 통합 배포 설정

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

# 환경별 변수
locals {
  domain_name = var.environment == "prod" ? var.domain_name : "${var.environment}.${var.domain_name}"
  
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    Phase       = "8"
    ManagedBy   = "Terraform"
  }
}

# DNS 모듈
module "dns" {
  source = "./dns"
  
  aws_region   = var.aws_region
  project_name = var.project_name
  domain_name  = local.domain_name
  environment  = var.environment
}

# SSL 모듈
module "ssl" {
  source = "./ssl"
  
  aws_region   = var.aws_region
  project_name = var.project_name
  domain_name  = local.domain_name
  
  depends_on = [module.dns]
}

# CDN 모듈
module "cdn" {
  source = "./cdn"
  
  aws_region   = var.aws_region
  project_name = var.project_name
  domain_name  = local.domain_name
  
  depends_on = [module.ssl]
}

# 보안 모듈
module "security" {
  source = "./security"
  
  aws_region                = var.aws_region
  project_name              = var.project_name
  cloudfront_distribution_id = module.cdn.cloudfront_distribution_id
  blocked_countries         = var.blocked_countries
  rate_limit               = var.rate_limit
  
  depends_on = [module.cdn]
}

# Parameter Store에 환경 설정 저장
resource "aws_ssm_parameter" "domain_name" {
  name  = "/${var.project_name}/${var.environment}/domain_name"
  type  = "String"
  value = local.domain_name
  
  tags = local.common_tags
}

resource "aws_ssm_parameter" "cloudfront_distribution_id" {
  name  = "/${var.project_name}/${var.environment}/cloudfront_distribution_id"
  type  = "String"
  value = module.cdn.cloudfront_distribution_id
  
  tags = local.common_tags
}

resource "aws_ssm_parameter" "certificate_arn" {
  name  = "/${var.project_name}/${var.environment}/certificate_arn"
  type  = "String"
  value = module.ssl.certificate_arn
  
  tags = local.common_tags
}

# KMS 키 (민감한 데이터 암호화용)
resource "aws_kms_key" "main" {
  description             = "${var.project_name} ${var.environment} encryption key"
  deletion_window_in_days = 7
  
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-key"
  })
}

resource "aws_kms_alias" "main" {
  name          = "alias/${var.project_name}-${var.environment}"
  target_key_id = aws_kms_key.main.key_id
}

# 암호화된 Parameter Store (민감한 설정용)
resource "aws_ssm_parameter" "api_keys" {
  name   = "/${var.project_name}/${var.environment}/api_keys"
  type   = "SecureString"
  key_id = aws_kms_key.main.key_id
  value = jsonencode({
    google_analytics = "GA-XXXXXXXXX"
    sentry_dsn      = "https://example@sentry.io/project"
  })
  
  tags = local.common_tags
}

# CloudWatch 대시보드 (Phase 8 전용)
resource "aws_cloudwatch_dashboard" "phase8" {
  dashboard_name = "${var.project_name}-Phase8-${var.environment}"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/CloudFront", "Requests", "DistributionId", module.cdn.cloudfront_distribution_id],
            [".", "BytesDownloaded", ".", "."],
            [".", "OriginLatency", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "CloudFront Metrics"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/WAFV2", "AllowedRequests", "WebACL", module.security.waf_web_acl_id, "Region", "CloudFront", "Rule", "ALL"],
            [".", "BlockedRequests", ".", ".", ".", ".", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1" # WAF CloudFront 메트릭은 us-east-1에만 있음
          title   = "WAF Security Metrics"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 24
        height = 6

        properties = {
          metrics = [
            ["AWS/Route53", "HealthCheckStatus", "HealthCheckId", module.dns.health_check_id],
            [".", "HealthCheckPercentHealthy", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "DNS Health Check"
          period  = 300
        }
      }
    ]
  })
}