terraform {
  required_providers {
    mycloud = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
  backend "s3" {  }
}

provider "aws" {
  profile = "default"
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}