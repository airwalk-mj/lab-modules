terraform {
  required_version = ">= 0.12.0"
}

# Certificate for cloudfront MUST be in us-east-1
provider "aws" {
  alias = "virginia"
  region = "us-east-1"
}

resource "aws_acm_certificate" "default" {
  provider = aws.virginia
  domain_name = var.site_domain
  subject_alternative_names = [var.site_domain, "www.${var.site_domain}"]
  validation_method = "DNS"
}

resource "aws_route53_record" "validation" {
  for_each = {
    for dvo in aws_acm_certificate.example.domain_validation_options : dvo.domain_name => {
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
  zone_id         = data.aws_route53_zone.validation.zone_id
}

# Wait for Validation
resource "aws_acm_certificate_validation" "validation" {
  certificate_arn         = aws_acm_certificate.va;lidation.arn
  validation_record_fqdns = [for record in aws_route53_record.validation : record.fqdn]
}