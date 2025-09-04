terraform {
  backend "s3" {
    bucket         = "tf-backup-aws-25072025" # ✅ Replace with your actual S3 bucket name
    key            = "poc/terraform.tfstate"  # ✅ State file path in S3
    region         = "ap-south-1"             # ✅ AWS region
    dynamodb_table = "tf-state-lock"          # ✅ DynamoDB table name for state locking
    encrypt        = true                     # ✅ Encrypt state file at rest
  }
}
