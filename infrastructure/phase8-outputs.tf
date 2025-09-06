output "domain_info" {
  description = "Domain and DNS information"
  value = {
    domain_name   = local.domain_name
    name_servers  = module.dns.name_servers
    zone_id       = module.dns.zone_id
    subdomains    = module.dns.subdomains
  }
}

output "ssl_info" {
  description = "SSL certificate information"
  value = {
    certificate_arn    = module.ssl.certificate_arn
    certificate_domain = module.ssl.certificate_domain
    https_listener_arn = module.ssl.https_listener_arn
    ssl_policy        = module.ssl.ssl_policy
  }
}

output "cdn_info" {
  description = "CloudFront CDN information"
  value = {
    distribution_id   = module.cdn.cloudfront_distribution_id
    domain_name      = module.cdn.cloudfront_domain_name
    static_bucket    = module.cdn.s3_static_bucket
    cdn_urls         = module.cdn.cdn_urls
  }
}

output "security_info" {
  description = "Security configuration information"
  value = {
    waf_web_acl_id     = module.security.waf_web_acl_id
    guardduty_detector = module.security.guardduty_detector_id
    vpc_flow_log      = module.security.vpc_flow_log_id
    monitoring        = module.security.security_monitoring
  }
}

output "environment_config" {
  description = "Environment configuration"
  value = {
    environment = var.environment
    kms_key_id  = aws_kms_key.main.key_id
    kms_alias   = aws_kms_alias.main.name
    dashboard   = "https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.phase8.dashboard_name}"
  }
}

output "application_urls" {
  description = "Application URLs"
  value = {
    main_site    = "https://${local.domain_name}"
    www_site     = "https://www.${local.domain_name}"
    api_endpoint = "https://api.${local.domain_name}"
    dashboard    = "https://dashboard.${local.domain_name}"
    admin        = "https://admin.${local.domain_name}"
    js_tracker   = "https://${local.domain_name}/js/liveinsight-tracker.js"
  }
}

output "deployment_summary" {
  description = "Phase 8 deployment summary"
  value = {
    phase           = "8"
    status          = "deployed"
    domain          = local.domain_name
    ssl_enabled     = true
    cdn_enabled     = true
    waf_enabled     = var.enable_waf
    guardduty_enabled = var.enable_guardduty
    environment     = var.environment
    deployment_time = timestamp()
  }
}