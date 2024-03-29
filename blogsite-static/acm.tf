resource "aws_acm_certificate" "cert" {
  provider = aws.use1
  domain_name       = var.site_domain
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
  tags = {
    Name = var.site_domain
  }
}
output "acm_dns_validation" {
  value = aws_acm_certificate.cert.domain_validation_options
}