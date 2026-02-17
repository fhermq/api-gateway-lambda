# Backend configuration for global infrastructure
# This stores the global state in S3 after initial creation

terraform {
  backend "s3" {
    bucket         = "terraform-state-444625565163-us-east-1"
    key            = "global/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
