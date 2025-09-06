variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "liveinsight"
}

variable "cloudfront_distribution_id" {
  description = "CloudFront distribution ID to associate with WAF"
  type        = string
}

variable "blocked_countries" {
  description = "List of country codes to block"
  type        = list(string)
  default     = [] # 빈 리스트 = 차단 안함
}

variable "rate_limit" {
  description = "Rate limit per IP (requests per 5 minutes)"
  type        = number
  default     = 2000
}