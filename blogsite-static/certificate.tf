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
  zone_id = "Z064458838N2OGDPML4NA"
  name    = "www.blog.lab.airwalkconsulting.com"
  type    = aws_acm_certificate.default.domain_validation_options.0.resource_record_type
  ttl     = "300"
  records = replace(aws_acm_certificate.default.domain_validation_options.0.resource_record_value, "/\\.$/", "")
}

resource "aws_route53_record" "alt_validation" {
  zone_id = "Z064458838N2OGDPML4NA"
  name    = "www.blog.lab.airwalkconsulting.com"
  type    = aws_acm_certificate.default.domain_validation_options.1.resource_record_type
  ttl     = "300"
  records = replace(aws_acm_certificate.default.domain_validation_options.1.resource_record_value, "/\\.$/", "")
}

# Wait for Validation
resource "aws_acm_certificate_validation" "default" {
  provider = aws.virginia
  certificate_arn = aws_acm_certificate.default.arn
  validation_record_fqdns = [
    dnsimple_record.validation.hostname,
    dnsimple_record.alt_validation.hostname
  ]
}
