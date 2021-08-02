provider "aws" {
  region = var.aws_region
}

resource "aws_s3_bucket" "blog" {
  bucket = var.site_domain
  acl    = "public-read"     
  website {    
    index_document = "index.html"    
    error_document = "404.html"   
  }
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
        Action    = "s3:GetObject"
        Principal = "*"
        Resource = [
          "${aws_s3_bucket.blog.arn}/*",
        ]
      },
    ]
  })
}