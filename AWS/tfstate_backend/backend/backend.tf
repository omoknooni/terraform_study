provider "aws" {
  shared_config_files = [ "~/.aws/config" ]
  shared_credentials_files = [ "~/.aws/credentials" ]
  profile = "hyeok"
  region = "ap-northeast-2"
}


# state 저장 버킷
resource "aws_s3_bucket" "tfstate_bucket" {
    bucket = "terraform-backend-omoknooni"
}

resource "aws_s3_bucket_versioning" "tfstate_bucket_versioning" {
    bucket = aws_s3_bucket.tfstate_bucket.id
    versioning_configuration {
        status = "Enabled"
    }
}

# state lock을 위한 dynamodb 테이블
resource "aws_dynamodb_table" "tfstate_lock_table" {
    name = "terraform-lock-omoknooni"
    billing_mode = "PAY_PER_REQUEST"
    hash_key = "LockID"

    attribute {
      name = "LockID"
      type = "S"
    }
}

output "bucket_name" {
    value = aws_s3_bucket.tfstate_bucket.arn
    description = "ARN of terraform backend bucket"
}

output "lock_table_name" {
    value = aws_dynamodb_table.tfstate_lock_table.arn
    description = "ARN of terraform backend lock table"
}