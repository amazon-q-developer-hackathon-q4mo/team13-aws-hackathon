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

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "static_files_bucket" {
  description = "S3 bucket name for static files"
  type        = string
}

variable "alb_logs_bucket" {
  description = "S3 bucket name for ALB logs"
  type        = string
  default     = ""
}