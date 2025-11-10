provider "aws" {
  region = var.region
}

# -------------------------------
# S3 Bucket (No ACL, ownership-enforced)
# -------------------------------
resource "aws_s3_bucket" "portfolio" {
  bucket = var.bucket_name

  tags = {
    Name    = "PortfolioBucket"
    Project = "Jagvi-Portfolio"
  }
}

# -------------------------------
# S3 Public Access Configuration
# -------------------------------
resource "aws_s3_bucket_public_access_block" "portfolio_public" {
  bucket                  = aws_s3_bucket.portfolio.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# -------------------------------
# S3 Website Configuration
# -------------------------------
resource "aws_s3_bucket_website_configuration" "portfolio_website" {
  bucket = aws_s3_bucket.portfolio.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

# -------------------------------
# S3 Bucket Policy (Public Read)
# -------------------------------
/*resource "aws_s3_bucket_policy" "public_policy" {
  bucket = aws_s3_bucket.portfolio.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Sid       = "PublicReadAccess",
      Effect    = "Allow",
      Principal = "*",
      Action    = "s3:GetObject",
      Resource  = "${aws_s3_bucket.portfolio.arn}/*"
    }]
  })
}
*/
# -------------------------------
# CloudFront Distribution
# -------------------------------
resource "aws_cloudfront_distribution" "cdn" {
  enabled             = true
  default_root_object = "index.html"

  origin {
    domain_name = aws_s3_bucket.portfolio.bucket_regional_domain_name
    origin_id   = "s3-portfolio-origin"
  }

  default_cache_behavior {
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]

    target_origin_id = "s3-portfolio-origin"
    forwarded_values {
      query_string = false
      cookies { forward = "none" }
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Project = "Jagvi-Portfolio"
  }
}

output "s3_bucket_name" {
  value = aws_s3_bucket.portfolio.bucket
}

output "cloudfront_domain" {
  value = aws_cloudfront_distribution.cdn.domain_name
}
