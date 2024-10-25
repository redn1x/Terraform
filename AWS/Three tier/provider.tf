################################
## AWS Provider Module - Main ##
################################

# AWS Provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region     = var.aws_region
}

terraform {
  backend "s3" {
    bucket         = "stg-terraform-files"
    key            = "Healthineers-Walpole/prod/terraform.tfstate"
    region         =  var.aws_region
    dynamodb_table = "terraform-lock-table"
  }
}