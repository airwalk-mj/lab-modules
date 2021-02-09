
locals {
  s3_origin_id = "S3-${var.site_domain}"
}

# Certificate for cloudfront MUST be in us-east-1
provider "aws" {
  alias = "virginia"
  region = "us-east-1"
}

data "aws_route53_zone" "my_zone" {
  zone_id = var.zone_id
}


######## I am a CERT !!!
resource "aws_acm_certificate" "blog" {
  provider                  = aws.virginia
  domain_name               = var.site_domain
  subject_alternative_names = [
    "blog.${var.site_domain}",
    "www.blog.${var.site_domain}",
  ]
  validation_method         = "DNS"
}

resource "aws_acm_certificate_validation" "blog" {
  provider                = aws.virginia
  certificate_arn         = aws_acm_certificate.blog.arn
  validation_record_fqdns = [for record in aws_route53_record.blog: record.fqdn]
}

resource "aws_route53_record" "blog" {
  provider = aws.virginia
  for_each = {
    for dvo in aws_acm_certificate.blog.domain_validation_options: dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }
  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.my_zone.zone_id
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

  aliases = ["blog.${var.site_domain}", "www.blog.${var.site_domain}"]

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
    minimum_protocol_version = var.minimum_protocol_version
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
    min_ttl = var.min_ttl
    max_ttl = var.max_ttl
    default_ttl = var.default_ttl
  }

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate_validation.blog.certificate_arn
    ssl_support_method = "sni-only"
    minimum_protocol_version = var.minimum_protocol_version
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

resource "aws_route53_record" "blog" {
  zone_id = var.zone_id
  name    = "blog.${var.site_domain}"
  type    = "A"

  alias {
    name                   = replace(aws_cloudfront_distribution.s3_distribution.domain_name, "/[.]$/", "")
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = true
  }

  depends_on = [aws_cloudfront_distribution.s3_distribution]
}
