
locals {
  s3_origin_id = "S3-${var.site_domain}"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = "${aws_s3_bucket.site.website_endpoint}"
    origin_id = "${local.s3_origin_id}"

    // The origin must be http even if it's on S3 for redirects to work properly
    // so the website_endpoint is used and http-only as S3 doesn't support https for this
    custom_origin_config {
      http_port = 80
      https_port = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols = ["TLSv1.2"]
    }
  }

  aliases = ["${var.site_domain}"]

  enabled = true
  is_ipv6_enabled = true
  default_root_object = "${var.default_root_object}"

  logging_config {
    bucket = "${aws_s3_bucket.site_log_bucket.bucket_domain_name}"
    include_cookies = false
  }

  default_cache_behavior {
    allowed_methods = ["GET", "HEAD"]
    cached_methods = ["GET", "HEAD"]
    target_origin_id = "${local.s3_origin_id}"

    "forwarded_values" {
      "cookies" {
        forward = "none"
      }
      query_string = false
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl = "${var.min_ttl}"
    max_ttl = "${var.max_ttl}"
    default_ttl = "${var.default_ttl}"
    compress = true
  }

  viewer_certificate {
    acm_certificate_arn = "${aws_acm_certificate_validation.default.certificate_arn}"
    ssl_support_method = "sni-only"
    minimum_protocol_version = "TLSv1.1_2016"
  }

  restrictions {
    "geo_restriction" {
      restriction_type = "none"
    }
  }

  custom_error_response  = "${var.custom_error_response}"
}
