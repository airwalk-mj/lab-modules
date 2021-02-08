terraform {
  required_version = ">= 0.12.0"
}

# Certificate for cloudfront MUST be in us-east-1
provider "aws" {
  alias = "virginia"
  region = "us-east-1"
}

data "aws_route53_zone" "site_domain" {
  name    = var.site_domain
  #zone_id = var.zone_id
}

resource "aws_acm_certificate" "lab" {
  domain_name               = "lab.${var.site_domain}"
  subject_alternative_names = [
    "lab1.${var.site_domain}",
    "lab2.${var.site_domain}",
    "lab3.${var.site_domain}",
  ]
  validation_method         = "DNS"
}

resource "aws_route53_record" "lab" {
  for_each = {
    for dvo in aws_acm_certificate.lab.domain_validation_options: dvo.domain_name => {
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
  zone_id         = data.aws_route53_zone.site_domain.zone_id
}

resource "aws_acm_certificate_validation" "lab" {
  certificate_arn         = aws_acm_certificate.lab.arn
  validation_record_fqdns = [for record in aws_route53_record.lab: record.fqdn]
}
