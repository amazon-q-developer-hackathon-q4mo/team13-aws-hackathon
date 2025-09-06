output "zone_id" {
  description = "Route 53 hosted zone ID"
  value       = aws_route53_zone.main.zone_id
}

output "name_servers" {
  description = "Route 53 name servers"
  value       = aws_route53_zone.main.name_servers
}

output "domain_name" {
  description = "Main domain name"
  value       = var.domain_name
}

output "subdomains" {
  description = "Configured subdomains"
  value = {
    www       = "www.${var.domain_name}"
    api       = "api.${var.domain_name}"
    dashboard = "dashboard.${var.domain_name}"
    admin     = "admin.${var.domain_name}"
  }
}

output "health_check_id" {
  description = "Route 53 health check ID"
  value       = aws_route53_health_check.main.id
}