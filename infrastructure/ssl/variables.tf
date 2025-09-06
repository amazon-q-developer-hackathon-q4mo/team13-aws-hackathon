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

variable "domain_name" {
  description = "Domain name for SSL certificate"
  type        = string
  default     = "liveinsight-demo.com"
}