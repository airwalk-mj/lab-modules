#resource "aws_route53_zone" "main" {
#  name = var.site_domain
#}

resource "aws_route53_record" "root-a" {
  zone_id = var.zone_id
  name    = var.site_domain
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.blog.domain_name
    zone_id                = aws_cloudfront_distribution.blog.hosted_zone_id
    evaluate_target_health = false
  }
}

#resource "aws_route53_record" "www-a" {
#  zone_id = aws_route53_zone.main.zone_id
#  name    = "www.${var.domain_name}"
#  type    = "A"

#  alias {
#    name                   = aws_cloudfront_distribution.www_s3_distribution.domain_name
#    zone_id                = aws_cloudfront_distribution.www_s3_distribution.hosted_zone_id
#    evaluate_target_health = false
#  }
#}