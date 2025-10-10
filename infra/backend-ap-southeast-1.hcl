terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
    bucket         = "tfstatebackup-10102025-southeast"
    key            = "dev/terraform.tfstate"
    region         = "ap-southeast-1"
    dynamodb_table = "terraformsoutheast-locks"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}