provider "aws" {
  region = "<your region>"
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "eks-dynamic-app-state-st"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}