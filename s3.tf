# Create an S3 bucket for storing Terraform state
resource "aws_s3_bucket" "terraform_state" {
  bucket = "jogesh-deployment-terraform-state-${random_id.s3_suffix.hex}"

  lifecycle {
    prevent_destroy = false
  }
}

resource "random_id" "s3_suffix" {
  byte_length = 4
}


# Create a DynamoDB table for Terraform state locking
resource "aws_dynamodb_table" "terraform_lock" {
  name         = "terraform-lock-table-${random_id.dynamodb_suffix.hex}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

resource "random_id" "dynamodb_suffix" {
  byte_length = 4
}

