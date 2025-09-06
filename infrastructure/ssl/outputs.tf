output "certificate_arn" {
  description = "ACM certificate ARN"
  value       = aws_acm_certificate_validation.main.certificate_arn
}

output "certificate_domain" {
  description = "Certificate domain name"
  value       = aws_acm_certificate.main.domain_name
}

output "certificate_status" {
  description = "Certificate validation status"
  value       = aws_acm_certificate.main.status
}

output "https_listener_arn" {
  description = "HTTPS listener ARN"
  value       = aws_lb_listener.https.arn
}

output "ssl_policy" {
  description = "SSL policy used"
  value       = aws_lb_listener.https.ssl_policy
}