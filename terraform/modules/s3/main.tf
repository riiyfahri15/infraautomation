# TODO: Implement this module.
# Read the README.md in this directory for the full list of resources to create.
# Refer to the Terraform documentation: https://registry.terraform.io/providers/hashicorp/aws/latest/docs


# resource "aws_s3_bucket" "tfstate" {
#   bucket = "lks-tfstate-fahri-2026"
# }
# 
# resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
#   bucket = aws_s3_bucket.tfstate.id
# 
#   rule {
#     apply_server_side_encryption_by_default {
#       sse_algorithm     = "AES256"
#     }
#   }
# }
# 
# resource "aws_s3_bucket_versioning" "tfstate" {
#   bucket = aws_s3_bucket.tfstate.id
#   versioning_configuration {
#     status = "Enabled"
#   }
# }
# 
# resource "aws_s3_bucket_lifecycle_configuration" "tfstate" {
#   bucket = aws_s3_bucket.tfstate.bucket
# 
#   rule {
#     id = "lks-rule"
# 
#     filter {}
# 
#     transition {
#       days          = 30
#       storage_class = "STANDARD_IA"
#     }
# 
#     noncurrent_version_expiration {
#       noncurrent_days = 365
#     }
# 
#     status = "Enabled"
#   }
# }
# 
# resource "aws_s3_bucket" "assets" {
#   bucket = "lks-app-assets-fahri-2026"
# }
# 
# resource "aws_s3_bucket_versioning" "assets" {
#   bucket = aws_s3_bucket.assets.id
#   versioning_configuration {
#     status = "Enabled"
#   }
# }
# 
# resource "aws_s3_bucket_policy" "assets" {
#   bucket = aws_s3_bucket.assets.id
#   policy = data.aws_iam_policy_document.assets.json
# }
# 
# data "aws_iam_policy_document" "assets" {
#   statement {
#     principals {
#       type        = "*"
#       identifiers = ["*"]
#     }
# 
#     actions = [
#       "s3:GetObject",
#     ]
# 
#     resources = [
#       "${aws_s3_bucket.assets.arn}/public/*",
#     ]
#   }
# }
# 
# resource "aws_s3_bucket_cors_configuration" "assets" {
#   bucket = aws_s3_bucket.assets.id
# 
#   cors_rule {
#     allowed_headers = ["*"]
#     allowed_methods = ["GET"]
#     allowed_origins = ["https://s3-website-test.hashicorp.com"]
#     expose_headers  = ["ETag"]
#     max_age_seconds = 3000
#   }
# }