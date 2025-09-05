# Random ID for unique bucket name
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# S3 버킷 생성
resource "aws_s3_bucket" "static_files" {
  bucket = "${var.project_name}-static-${var.environment}-${random_id.bucket_suffix.hex}"

  tags = {
    Name = "${var.project_name}-static-files"
  }
}

# S3 버킷 웹사이트 설정
resource "aws_s3_bucket_website_configuration" "static_files" {
  bucket = aws_s3_bucket.static_files.id

  index_document {
    suffix = "dashboard.html"
  }

  error_document {
    key = "error.html"
  }
}

# S3 버킷 퍼블릭 액세스 설정
resource "aws_s3_bucket_public_access_block" "static_files" {
  bucket = aws_s3_bucket.static_files.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# S3 버킷 정책
resource "aws_s3_bucket_policy" "static_files" {
  bucket = aws_s3_bucket.static_files.id
  depends_on = [aws_s3_bucket_public_access_block.static_files]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.static_files.arn}/*"
      },
    ]
  })
}

# CloudFront Origin Access Control
resource "aws_cloudfront_origin_access_control" "static_files" {
  name                              = "${var.project_name}-static-oac-${var.environment}"
  description                       = "OAC for LiveInsight static files"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "static_files" {
  origin {
    domain_name              = aws_s3_bucket.static_files.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.static_files.id
    origin_id                = "S3-${aws_s3_bucket.static_files.id}"
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "dashboard.html"

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.static_files.id}"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
  }

  # API 경로를 위한 추가 캐시 동작
  ordered_cache_behavior {
    path_pattern     = "/api/*"
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "API-Gateway"

    forwarded_values {
      query_string = true
      headers      = ["Authorization", "Content-Type"]
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "https-only"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
    compress               = true
  }

  # API Gateway Origin
  origin {
    domain_name = "${aws_api_gateway_rest_api.liveinsight_api.id}.execute-api.${data.aws_region.current.name}.amazonaws.com"
    origin_id   = "API-Gateway"
    origin_path = "/${var.environment}"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Name = "${var.project_name}-cloudfront"
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

# 기본 대시보드 HTML 파일 업로드
resource "aws_s3_object" "dashboard_html" {
  bucket       = aws_s3_bucket.static_files.id
  key          = "dashboard.html"
  content_type = "text/html"

  content = <<EOF
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>LiveInsight Dashboard</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1 { color: #333; text-align: center; }
        .status { padding: 20px; background: #e8f5e8; border-radius: 4px; margin: 20px 0; }
        .api-test { margin: 20px 0; padding: 15px; background: #f8f9fa; border-radius: 4px; }
        button { background: #007bff; color: white; border: none; padding: 10px 20px; border-radius: 4px; cursor: pointer; margin: 5px; }
        button:hover { background: #0056b3; }
        .result { margin-top: 10px; padding: 10px; background: #fff; border: 1px solid #ddd; border-radius: 4px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 LiveInsight Dashboard</h1>
        
        <div class="status">
            <h3>✅ Phase 2 인프라 배포 완료!</h3>
            <p>API Gateway, S3, CloudFront가 성공적으로 구성되었습니다.</p>
        </div>

        <div class="api-test">
            <h3>API 테스트</h3>
            <button onclick="testAPI('/api/events', 'POST')">POST /api/events</button>
            <button onclick="testAPI('/api/realtime', 'GET')">GET /api/realtime</button>
            <button onclick="testAPI('/api/stats', 'GET')">GET /api/stats</button>
            <div id="api-result" class="result" style="display:none;"></div>
        </div>

        <div class="api-test">
            <h3>시스템 정보</h3>
            <p><strong>배포 환경:</strong> ${var.environment}</p>
            <p><strong>리전:</strong> ${data.aws_region.current.name}</p>
            <p><strong>배포 시간:</strong> <span id="deploy-time"></span></p>
        </div>
    </div>

    <script>
        // 배포 시간 표시
        document.getElementById('deploy-time').textContent = new Date().toLocaleString('ko-KR');

        // API 테스트 함수
        async function testAPI(endpoint, method) {
            const resultDiv = document.getElementById('api-result');
            resultDiv.style.display = 'block';
            resultDiv.innerHTML = '테스트 중...';

            try {
                const options = {
                    method: method,
                    headers: {
                        'Content-Type': 'application/json',
                    }
                };

                if (method === 'POST') {
                    options.body = JSON.stringify({
                        test: true,
                        timestamp: Date.now(),
                        message: 'Dashboard test'
                    });
                }

                const response = await fetch(endpoint, options);
                const data = await response.text();
                
                resultDiv.innerHTML = `
                    <strong>$${method} $${endpoint}</strong><br>
                    <strong>Status:</strong> $${response.status}<br>
                    <strong>Response:</strong><br>
                    <pre>$${data}</pre>
                `;
            } catch (error) {
                resultDiv.innerHTML = `
                    <strong>Error:</strong> $${error.message}
                `;
            }
        }
    </script>
</body>
</html>
EOF

  tags = {
    Name = "dashboard-html"
  }
}

# 에러 페이지
resource "aws_s3_object" "error_html" {
  bucket       = aws_s3_bucket.static_files.id
  key          = "error.html"
  content_type = "text/html"

  content = <<EOF
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>LiveInsight - 오류</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; text-align: center; }
        .container { max-width: 600px; margin: 0 auto; background: white; padding: 40px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1 { color: #dc3545; }
    </style>
</head>
<body>
    <div class="container">
        <h1>⚠️ 페이지를 찾을 수 없습니다</h1>
        <p>요청하신 페이지가 존재하지 않습니다.</p>
        <a href="/">대시보드로 돌아가기</a>
    </div>
</body>
</html>
EOF

  tags = {
    Name = "error-html"
  }
}

# 데이터 소스
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}