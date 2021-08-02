resource "aws_s3_bucket" "blog" {
  bucket = var.site_domain
  acl    = "private"
}

resource "aws_s3_bucket" "logs" {
  bucket = "logs.${var.site_domain}"
  acl    = "private"
}

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