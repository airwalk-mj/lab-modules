
terraform {
  required_version = ">= 0.14.9"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 3.27.0"
    }
    null = {
      version = "~> 3.0.0"
    }
  }
}

provider "aws" {
  region  = var.aws_region
}

#provider "random" {
#  version = "~> 2.3"
#}

resource "aws_s3_bucket" "site" {
  bucket = var.site_domain

  website {
    index_document = var.bucket_index_document
    error_document = var.bucket_error_document
  }

  logging {
    target_bucket = aws_s3_bucket.site_log_bucket.id
  }

  versioning {
    enabled = true
  }
}

resource "aws_s3_bucket" "redirect_to_apex" {
  bucket = "www.${var.site_domain}"

  website {
    redirect_all_requests_to = "https://${var.site_domain}"
  }
}

resource "aws_s3_bucket" "site_log_bucket" {
  bucket = "${var.site_domain}-logs"
  acl = "log-delivery-write"
}

resource "aws_s3_bucket_policy" "site" {
  bucket = aws_s3_bucket.site.id
  policy = data.aws_iam_policy_document.site_public_access.json
}

data "aws_iam_policy_document" "site_public_access" {
  statement {
    actions = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.site.arn}/*"]

    principals {
      type = "AWS"
      identifiers = ["*"]
    }
  }

  statement {
    actions = ["s3:ListBucket"]
    resources = [aws_s3_bucket.site.arn]

    principals {
      type = "AWS"
      identifiers = ["*"]
    }
  }
}

resource "aws_s3_bucket_policy" "redirect_to_apex" {
  bucket = aws_s3_bucket.redirect_to_apex.id
  policy = data.aws_iam_policy_document.redirect_to_apex.json
}

data "aws_iam_policy_document" "redirect_to_apex" {
  statement {
    actions = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.redirect_to_apex.arn}/*"]

    principals {
      type = "AWS"
      identifiers = ["*"]
    }
  }

  statement {
    actions = ["s3:ListBucket"]
    resources = [aws_s3_bucket.redirect_to_apex.arn]

    principals {
      type = "AWS"
      identifiers = ["*"]
    }
  }
}
