terraform {
  required_version = ">= 0.12.0"
}

# Certificate for cloudfront MUST be in us-east-1
provider "aws" {
  alias = "virginia"
  region = "us-east-1"
}

resource "aws_acm_certificate" "default" {
  provider = "aws.virginia"
  domain_name = var.site_domain
  subject_alternative_names = [var.site_domain, "www.${var.site_domain}"]
  validation_method = "DNS"
}

resource "dns_record" "validation" {
  domain = var.site_domain

  // remove the apex domain from the resource_record_name otherwise dnsimple errors
  name  = "${replace(aws_acm_certificate.default.domain_validation_options.0.resource_record_name, ".${var.site_domain}.", "")}"
  type  = "${aws_acm_certificate.default.domain_validation_options.0.resource_record_type}"
  // Remove the trailing . as dnsimple removes it anyway and the domain still gets validated.
  // If the . isn't removed then this will always want to update
  value = "${replace(aws_acm_certificate.default.domain_validation_options.0.resource_record_value, "/\\.$/", "")}"
  ttl = "60"
}

resource "dns_record" "alt_validation" {
  domain = var.site_domain
  // remove the apex domain from the resource_record_name otherwise dnsimple errors
  name  = "${replace(aws_acm_certificate.default.domain_validation_options.1.resource_record_name, ".${var.site_domain}.", "")}"
  type  = "${aws_acm_certificate.default.domain_validation_options.1.resource_record_type}"
  // Remove the trailing . as dnsimple removes it anyway and the domain still gets validated.
  // If the . isn't removed then this will always want to update
  value = "${replace(aws_acm_certificate.default.domain_validation_options.1.resource_record_value, "/\\.$/", "")}"
  ttl = "60"
}

# Wait for Validation
resource "aws_acm_certificate_validation" "default" {
  provider = "aws.virginia"
  certificate_arn = aws_acm_certificate.default.arn
  validation_record_fqdns = [
    dnsimple_record.validation.hostname,
    dnsimple_record.alt_validation.hostname
  ]
}
