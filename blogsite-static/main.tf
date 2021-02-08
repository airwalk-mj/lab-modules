terraform {
  required_version = ">= 0.12.0"
}

resource "aws_s3_bucket" "site" {
        bucket = var.site_domain
      
        website {
          index_document = var.bucket_index_document
          error_document = var.bucket_error_document
        }
      
        logging {
          target_bucket = aws_s3_bucket.site_log_bucket.id
        }
      
        versioning {
          enabled = true
        }
      }
      
      resource "aws_s3_bucket" "redirect_to_apex" {
        bucket = "www.${var.site_domain}"
      
        website {
          redirect_all_requests_to = "https://${var.site_domain}"
        }
      }
      
      resource "aws_s3_bucket" "site_log_bucket" {
        bucket = "${var.site_domain}-logs"
        acl = "log-delivery-write"
      }

      resource "aws_s3_bucket_policy" "site" {
        bucket = aws_s3_bucket.site.id
        policy = data.aws_iam_policy_document.site_public_access.json
      }
      
      data "aws_iam_policy_document" "site_public_access" {
        statement {
          actions = ["s3:GetObject"]
          resources = ["${aws_s3_bucket.site.arn}/*"]
      
          principals {
            type = "AWS"
            identifiers = ["*"]
          }
        }
      
        statement {
          actions = ["s3:ListBucket"]
          resources = ["${aws_s3_bucket.site.arn}"]
      
          principals {
            type = "AWS"
            identifiers = ["*"]
          }
        }
      }
      
      resource "aws_s3_bucket_policy" "redirect_to_apex" {
        bucket = "${aws_s3_bucket.redirect_to_apex.id}"
        policy = data.aws_iam_policy_document.redirect_to_apex.json
      }
      
      data "aws_iam_policy_document" "redirect_to_apex" {
        statement {
          actions = ["s3:GetObject"]
          resources = ["${aws_s3_bucket.redirect_to_apex.arn}/*"]
      
          principals {
            type = "AWS"
            identifiers = ["*"]
          }
        }
      
        statement {
          actions = ["s3:ListBucket"]
          resources = ["${aws_s3_bucket.redirect_to_apex.arn}"]
      
          principals {
            type = "AWS"
            identifiers = ["*"]
          }
        }
      }

---

# Needed because certificate for cloudfront must be in us-east-1
provider "aws" {
  alias = "virginia"
  region = "us-east-1"
}

resource "aws_acm_certificate" "default" {
  provider = "aws.virginia"
  domain_name = "${var.site_domain}"
  subject_alternative_names = [var.site_domain, "www.${var.site_domain}"]
  validation_method = "DNS"
}

resource "dnsimple_record" "validation" {
  domain = "${var.site_domain}"
  // remove the apex domain from the resource_record_name otherwise dnsimple errors
  name  = "${replace(aws_acm_certificate.default.domain_validation_options.0.resource_record_name, ".${var.site_domain}.", "")}"
  type  = "${aws_acm_certificate.default.domain_validation_options.0.resource_record_type}"
  // Remove the trailing . as dnsimple removes it anyway and the domain still gets validated.
  // If the . isn't removed then this will always want to update
  value = "${replace(aws_acm_certificate.default.domain_validation_options.0.resource_record_value, "/\\.$/", "")}"
  ttl = "60"
}

resource "dnsimple_record" "alt_validation" {
  domain = "${var.site_domain}"
  // remove the apex domain from the resource_record_name otherwise dnsimple errors
  name  = "${replace(aws_acm_certificate.default.domain_validation_options.1.resource_record_name, ".${var.site_domain}.", "")}"
  type  = "${aws_acm_certificate.default.domain_validation_options.1.resource_record_type}"
  // Remove the trailing . as dnsimple removes it anyway and the domain still gets validated.
  // If the . isn't removed then this will always want to update
  value = "${replace(aws_acm_certificate.default.domain_validation_options.1.resource_record_value, "/\\.$/", "")}"
  ttl = "60"
}

resource "aws_acm_certificate_validation" "default" {
  provider = "aws.virginia"
  certificate_arn = "${aws_acm_certificate.default.arn}"
  validation_record_fqdns = [
    dnsimple_record.validation.hostname,
    dnsimple_record.alt_validation.hostname
  ]
}

---

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
      
        aliases = ["${var.site_domain}"]
      
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
      
          "forwarded_values" {
            "cookies" {
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
          acm_certificate_arn = aws_acm_certificate_validation.default.certificate_arn
          ssl_support_method = "sni-only"
          minimum_protocol_version = "TLSv1.1_2016"
        }
      
        restrictions {
          "geo_restriction" {
            restriction_type = "none"
          }
        }
      
        custom_error_response  = var.custom_error_response
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
      
          "forwarded_values" {
            "cookies" {
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
          acm_certificate_arn = "${aws_acm_certificate_validation.default.certificate_arn}"
          ssl_support_method = "sni-only"
          minimum_protocol_version = "TLSv1.1_2016"
        }
      
        restrictions {
          "geo_restriction" {
            restriction_type = "none"
          }
        }
      }

---

resource "dnsimple_record" "access" {
        domain = var.site_domain
        name = ""
        type = "ALIAS"
        value = aws_cloudfront_distribution.s3_distribution.domain_name
        ttl = "3600"
      }
      
      resource "dnsimple_record" "alt_access" {
        domain = var.site_domain
        name = "www"
        type = "CNAME"
        value = aws_cloudfront_distribution.redirect_distribution.domain_name
        ttl = "3600"
      }
  