terraform {
  required_version = ">= 0.12.0"
}


# create a non-aliased provider along with the aliased providers
provider "aws" {
  region = var.aws_region
}
 
# required for cloudfront
provider "aws" {
  alias   = "use1"
  region  = "us-east-1"
  version = "~> 2.54"
}