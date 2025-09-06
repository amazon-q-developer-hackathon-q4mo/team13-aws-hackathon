output "waf_web_acl_id" {
  description = "WAF Web ACL ID"
  value       = aws_wafv2_web_acl.main.id
}

output "waf_web_acl_arn" {
  description = "WAF Web ACL ARN"
  value       = aws_wafv2_web_acl.main.arn
}

output "guardduty_detector_id" {
  description = "GuardDuty detector ID"
  value       = aws_guardduty_detector.main.id
}

output "vpc_flow_log_id" {
  description = "VPC Flow Log ID"
  value       = aws_flow_log.vpc.id
}

output "security_monitoring" {
  description = "Security monitoring endpoints"
  value = {
    waf_logs      = aws_cloudwatch_log_group.waf.name
    vpc_flow_logs = aws_cloudwatch_log_group.vpc_flow_log.name
    guardduty     = "https://console.aws.amazon.com/guardduty/home?region=${var.aws_region}#/findings"
  }
}