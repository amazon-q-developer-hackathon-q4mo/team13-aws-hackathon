output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.main.id
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.main.domain_name
}

output "s3_static_bucket" {
  description = "S3 static assets bucket name"
  value       = aws_s3_bucket.static_assets.bucket
}

output "s3_logs_bucket" {
  description = "S3 CloudFront logs bucket name"
  value       = aws_s3_bucket.logs.bucket
}

output "cdn_urls" {
  description = "CDN URLs for static assets"
  value = {
    js_tracker = "https://${var.domain_name}/js/liveinsight-tracker.js"
    static_url = "https://${var.domain_name}/static/"
  }
}