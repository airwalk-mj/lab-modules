
locals {
  s3_origin_id = "S3-${var.site_domain}"
}

resource "aws_cloudfront_distribution" "blog" {

  provider = aws.use1

  origin {
    #domain_name = aws_s3_bucket.blog.bucket_regional_domain_name
    domain_name = aws_s3_bucket.blog.website_endpoint
    origin_id   = local.s3_origin_id

    // The origin must be http even if it's on S3 for redirects to work properly
    // so the website_endpoint is used and http-only as S3 doesn't support https for this
    custom_origin_config {
      http_port = 80
      https_port = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols = ["TLSv1.2"]
    }

    #s3_origin_config {
    #  origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
    #}
  }

  enabled             = true
  is_ipv6_enabled     = false
  default_root_object = var.default_root_object

  #logging_config {
  #  include_cookies = false
  #  bucket          = aws_s3_bucket.logs.bucket_domain_name
  #  prefix          = ""
  #}

  aliases = [var.site_domain]

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
    compress = true
    viewer_protocol_policy = "allow-all"
    min_ttl                = var.min_ttl
    default_ttl            = var.default_ttl
    max_ttl                = var.max_ttl
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  price_class = "PriceClass_100"

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate.cert.arn
    ssl_support_method = "sni-only"
    minimum_protocol_version = var.minimum_protocol_version
  }
}