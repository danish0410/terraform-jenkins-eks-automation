terraform {
  backend "s3" {
    bucket         = "tf-backup-aws"
    key            = "dev/terraform.tfstate" # overridden by -backend-config
    region         = "ap-south-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}