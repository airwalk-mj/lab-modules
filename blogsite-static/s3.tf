
resource "aws_s3_bucket" "blog" {
  bucket = var.site_domain
  acl    = "private"

  #cors_rule {
  #  allowed_headers = ["Authorization", "Content-Length"]
  #  allowed_methods = ["GET"]
  #  allowed_origins = ["https://${var.site_domain}"]
  #  max_age_seconds = 3000
  #}
  
  versioning {
    enabled = false
  }

  website {
    index_document = var.bucket_index_document
    error_document = var.bucket_error_document
  }
}


## Also uncomment logging_config in cloudfront.tf
#resource "aws_s3_bucket" "logs" {
#  bucket = "logs.${var.site_domain}"
#  acl    = "private"
#}

#data "aws_iam_policy_document" "blog_s3_policy" {
#  statement {
#    actions = ["s3:GetObject"]
#    resources = ["${aws_s3_bucket.blog.arn}/*"]

#    principals {
#      type = "AWS"
#      identifiers = ["*"]
#    }
#  }
#}


data "aws_iam_policy_document" "blog_public_access" {
  statement {
    actions = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.blog.arn}/*"]

    principals {
      type = "AWS"
      identifiers = ["*"]
    }
  }

  statement {
    actions = ["s3:GetObject"]
    resources = [aws_s3_bucket.blog.arn]

    principals {
      type = "AWS"
      identifiers = ["*"]
    }
  }
}

resource "aws_s3_bucket_policy" "blog" {
  bucket = aws_s3_bucket.blog.id
  policy = data.aws_iam_policy_document.blog_public_access.json
}

#resource "aws_s3_bucket_policy" "blog" {
#  bucket = aws_s3_bucket.blog.id
#  policy = data.aws_iam_policy_document.blog_s3_policy.json
#}

locals {
  s3_origin_id = "blogs3origin"
}

resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {}