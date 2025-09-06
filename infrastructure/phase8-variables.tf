# Phase 8 전용 변수들 (기본 변수는 variables.tf에 정의됨)

variable "domain_name" {
  description = "Base domain name"
  type        = string
  default     = "liveinsight-demo.com"
}

variable "blocked_countries" {
  description = "List of country codes to block (ISO 3166-1 alpha-2)"
  type        = list(string)
  default     = []
  
  validation {
    condition = alltrue([
      for country in var.blocked_countries : length(country) == 2
    ])
    error_message = "Country codes must be 2-letter ISO 3166-1 alpha-2 codes."
  }
}

variable "rate_limit" {
  description = "WAF rate limit per IP (requests per 5 minutes)"
  type        = number
  default     = 2000
  
  validation {
    condition     = var.rate_limit >= 100 && var.rate_limit <= 20000000
    error_message = "Rate limit must be between 100 and 20,000,000."
  }
}

variable "enable_waf" {
  description = "Enable WAF protection"
  type        = bool
  default     = true
}

variable "enable_guardduty" {
  description = "Enable GuardDuty threat detection"
  type        = bool
  default     = true
}

variable "ssl_policy" {
  description = "SSL policy for ALB"
  type        = string
  default     = "ELBSecurityPolicy-TLS-1-2-2017-01"
}