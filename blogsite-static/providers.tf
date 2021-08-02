
terraform {
  required_version = ">= 0.13.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.52.0"
    }
  }
}

#terraform {
#  required_version = ">= 0.13.0"
#}

# create a non-aliased provider along with the aliased providers
provider "aws" {
  region = var.aws_region
}
 
# required for cloudfront
provider "aws" {
  alias   = "use1"
  region  = "us-east-1"
}