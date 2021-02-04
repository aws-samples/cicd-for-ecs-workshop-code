provider "aws" {
  profile = "default"
  version = "~> 2.64"
}

terraform {
  backend "s3" {  }
}


data "aws_caller_identity" "current" {}

data "aws_region" "current" {}