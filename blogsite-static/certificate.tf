terraform {
  required_version = ">= 0.12.0"
}

# Certificate for cloudfront MUST be in us-east-1
provider "aws" {
  alias = "virginia"
  region = "us-east-1"
}




resource "aws_acm_certificate" "cert" {
  domain_name       = var.site_domain
  validation_method = "DNS"
}

#resource "aws_acm_certificate" "default" {
#  provider = aws.virginia
#  domain_name = var.site_domain
#  validation_method = "DNS"
#  subject_alternative_names = [var.site_domain, "www.${var.site_domain}"]
#}

data "aws_route53_zone" "lab" {
  name    = "lab.airwalkconsulting.io"
  zone_id = "Z064458838N2OGDPML4NA"
}

resource "aws_route53_record" "cert-validation" {
  name    = aws_acm_certificate.cert.domain_validation_options[0].resource_record_name
  type    = aws_acm_certificate.cert.domain_validation_options[0].resource_record_type
  zone_id = data.aws_route53_zone.lab.zone_id
  records = [aws_acm_certificate.cert.domain_validation_options[0].resource_record_value]
  ttl     = "60"
}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [aws_route53_record.cert-validation.fqdn]
}