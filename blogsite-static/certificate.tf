terraform {
  required_version = ">= 0.12.0"
}

# Certificate for cloudfront MUST be in us-east-1
provider "aws" {
  alias = "virginia"
  region = "us-east-1"
}

data "aws_route53_zone" "public_root_domain" {
  name    = var.public_root_domain
}

resource "aws_acm_certificate" "blog" {
  domain_name               = "blog.${var.public_root_domain}"
  subject_alternative_names = [
    "blog1.${var.public_root_domain}",
    "blog2.${var.public_root_domain}",
    "blog3.${var.public_root_domain}",
  ]
  validation_method         = "DNS"
}

resource "aws_route53_record" "existing" {
  for_each = {
    for dvo in aws_acm_certificate.existing.domain_validation_options: dvo.domain_name => {
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
  zone_id         = data.aws_route53_zone.public_root_domain.zone_id
}

resource "aws_acm_certificate_validation" "existing" {
  certificate_arn         = aws_acm_certificate.existing.arn
  validation_record_fqdns = [for record in aws_route53_record.existing: record.fqdn]
}
