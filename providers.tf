# terraform {
#   backend "s3" {
#     bucket         = "terraform_state_file"  # Replace with your bucket name
#     key            = "terraform.tfstate"
#     region         = "us-east-1"
#     encrypt        = true
#     dynamodb_table = "terraform-lock-table"  # For state locking
#   }
# }

provider "aws" {
  region = "us-east-1"
}