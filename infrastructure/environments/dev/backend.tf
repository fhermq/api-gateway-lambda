# Backend configuration for dev environment
# This stores the dev state in S3 with DynamoDB locking

terraform {
  backend "s3" {
    bucket         = "terraform-state-444625565163-us-east-1"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
