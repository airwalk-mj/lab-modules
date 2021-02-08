terraform {
  required_version = ">= 0.12.0"
}

# Certificate for cloudfront MUST be in us-east-1
provider "aws" {
  alias = "virginia"
  region = "us-east-1"
}

data "aws_route53_zone" "public_root_domain" {
  name = var.public_root_domain
}
resource "aws_acm_certificate" "existing" {
  domain_name               = "existing.${var.public_root_domain}"
  subject_alternative_names = [
    "existing1.${var.public_root_domain}",
    "existing2.${var.public_root_domain}",
    "existing3.${var.public_root_domain}",
  ]
  validation_method         = "DNS"
}
resource "aws_route53_record" "existing" {
  count = length(aws_acm_certificate.existing.subject_alternative_names) + 1
  allow_overwrite = true
  name            = aws_acm_certificate.existing.domain_validation_options[count.index].resource_record_name
  records         = [aws_acm_certificate.existing.domain_validation_options[count.index].resource_record_value]
  ttl             = 60
  type            = aws_acm_certificate.existing.domain_validation_options[count.index].resource_record_type
  zone_id         = data.aws_route53_zone.public_root_domain.zone_id
}
resource "aws_acm_certificate_validation" "existing" {
  certificate_arn         = aws_acm_certificate.existing.arn
  validation_record_fqdns = aws_route53_record.existing[*].fqdn
}
