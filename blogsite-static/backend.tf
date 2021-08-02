terraform {
  backend "s3" {
    bucket         = "tf-state-aws-sandbox21-eu-west-2"
    dynamodb_table = "tf-locks"
    encrypt        = true
    key            = "eu-west-2/dev/blogsite-static/tfstate.tfstate"
    region         = "eu-west-2"
  }
}