# JavaScript SDK용 퍼블릭 S3 버킷
resource "aws_s3_bucket" "js_sdk" {
  bucket = "liveinsight-js-sdk-${random_string.suffix.result}"
}

resource "aws_s3_bucket_public_access_block" "js_sdk" {
  bucket = aws_s3_bucket.js_sdk.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "js_sdk" {
  bucket = aws_s3_bucket.js_sdk.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.js_sdk.arn}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.js_sdk]
}

resource "aws_s3_bucket_cors_configuration" "js_sdk" {
  bucket = aws_s3_bucket.js_sdk.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
    max_age_seconds = 3000
  }
}

resource "aws_s3_object" "tracker_js" {
  bucket       = aws_s3_bucket.js_sdk.id
  key          = "liveinsight-tracker.js"
  source       = "${path.module}/../../static/js/liveinsight-tracker.js"
  content_type = "application/javascript"
  etag         = filemd5("${path.module}/../../static/js/liveinsight-tracker.js")
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

output "js_sdk_bucket_name" {
  value = aws_s3_bucket.js_sdk.id
}

output "js_sdk_url" {
  value = "https://${aws_s3_bucket.js_sdk.bucket_domain_name}/liveinsight-tracker.js"
}