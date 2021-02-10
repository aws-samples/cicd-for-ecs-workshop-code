terraform {
  required_providers {
    mycloud = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  profile = "default"
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}


# Bucket for Terraform state

resource "aws_s3_bucket" "terraform_bucket" {
}


# Outputs

output "terraform_bucket_name" {
  value = aws_s3_bucket.terraform_bucket.id
}