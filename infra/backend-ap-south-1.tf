terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
    bucket         = "tfstatebackup-09102025-south"
    key            = "dev/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "terraformsouth-locks"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}