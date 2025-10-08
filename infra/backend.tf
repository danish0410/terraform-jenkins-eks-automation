terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
    bucket         = "tfstatebackup-25092025"
    key            = "ap-south-1/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}