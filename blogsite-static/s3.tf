
resource "aws_s3_bucket" "blog" {
  bucket = var.site_domain
  acl    = "private"

  cors_rule {
    allowed_headers = ["Authorization", "Content-Length"]
    allowed_methods = ["GET"]
    allowed_origins = ["https://${var.site_name}"]
    max_age_seconds = 3000
  }

  website {
    index_document = "index.html"
    error_document = "404.html"
  }
}

## Also uncomment logging_config in cloudfront.tf
#resource "aws_s3_bucket" "logs" {
#  bucket = "logs.${var.site_domain}"
#  acl    = "private"
#}

data "aws_iam_policy_document" "blog_s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.blog.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn]
    }
  }

  statement {
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.blog.arn]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "blog" {
  bucket = aws_s3_bucket.blog.id
  policy = data.aws_iam_policy_document.blog_s3_policy.json
}

locals {
  s3_origin_id = "blogs3origin"
}

resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
}