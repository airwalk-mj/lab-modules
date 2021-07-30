provider "aws" {
  region = var.aws_region
}

resource "aws_s3_bucket" "blog" {
  bucket = var.site_domain
  acl    = "public-read"
  tags = {
    Name        = var.site_domain
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_policy" "blog" {
  bucket = aws_s3_bucket.blog.id

  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "PublicRead"
    Statement = [
      {
        Sid       = "PublicRead"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource = [
          aws_s3_bucket.blog.arn,
          "${aws_s3_bucket.blog.arn}/*",
        ]
      },
    ]
  })
}