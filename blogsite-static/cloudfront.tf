
locals {
  s3_origin_id = "S3-${var.site_domain}"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = aws_s3_bucket.site.website_endpoint
    origin_id = local.s3_origin_id

    // The origin must be http even if it's on S3 for redirects to work properly
    // so the website_endpoint is used and http-only as S3 doesn't support https for this
    custom_origin_config {
      http_port = 80
      https_port = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols = ["TLSv1.2"]
    }
  }

  aliases = [var.site_domain]

  enabled = true
  is_ipv6_enabled = true
  default_root_object = var.default_root_object

  logging_config {
    bucket = aws_s3_bucket.site_log_bucket.bucket_domain_name
    include_cookies = false
  }

  default_cache_behavior {
    allowed_methods = ["GET", "HEAD"]
    cached_methods = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      cookies {
        forward = "none"
      }
      query_string = false
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl = var.min_ttl
    max_ttl = var.max_ttl
    default_ttl = var.default_ttl
    compress = true
  }

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate_validation.blog.certificate_arn
    ssl_support_method = "sni-only"
    minimum_protocol_version = "TLSv1.1_2016"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

resource "aws_cloudfront_distribution" "redirect_distribution" {
  origin {
    domain_name = aws_s3_bucket.redirect_to_apex.website_endpoint
    origin_id = local.s3_origin_id

    // The redirect origin must be http even if it's on S3 for redirects to work properly
    // so the website_endpoint is used and http-only as S3 doesn't support https for this
    custom_origin_config {
      http_port = 80
      https_port = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols = ["TLSv1.2"]
    }
  }

  aliases = ["www.${var.site_domain}"]

  enabled = true
  is_ipv6_enabled = true

  default_cache_behavior {
    allowed_methods = ["GET", "HEAD"]
    cached_methods = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      cookies {
        forward = "none"
      }
      query_string = false
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl = 0
    max_ttl = 31536000
    default_ttl = 86400
  }

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate_validation.default.certificate_arn
    ssl_support_method = "sni-only"
    minimum_protocol_version = "TLSv1.1_2016"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

resource "aws_route53_record" "access" {
  domain = var.site_domain
  name = ""
  type = "ALIAS"
  value = aws_cloudfront_distribution.s3_distribution.domain_name
  ttl = "3600"
}

resource "aws_route53_record" "alt_access" {
  domain = var.site_domain
  name = "www"
  type = "CNAME"
  value = aws_cloudfront_distribution.redirect_distribution.domain_name
  ttl = "3600"
}
