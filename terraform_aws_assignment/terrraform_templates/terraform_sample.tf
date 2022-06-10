terraform {

  required_providers {

    aws = {

      source = "hashicorp/aws"

    }

  }

  required_version = ">= 0.12"

}

provider "aws" {

  profile = "default"

  region = "eu-north-1"

}

##########################################################
##Create Source and Destination Buckets##
##########################################################
resource "aws_s3_bucket" "demo" {

  bucket = "demosrinadhunisourceimagebucket"

}

resource "aws_s3_bucket" "demo1" {

  bucket = "demosrinadhunisourceimagebucket-resized"

}

##########################################################
##Create Lambda Function##
##########################################################

module "lambda_function_existing_package_local" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = "my-lambda-existing-package-local"
  description   = "Lambda function to resize images"
  handler       = "CreateThumbnail.lambda_handler"
  runtime       = "python3.7"

  create_package         = false
  local_existing_package = "../CreateThumbnail.zip"
#  allowed_triggers = {
#   S3 = {
#    principal = "s3.amazonaws.com"
#    source_arn = "arn:aws:s3:::${aws_s3_bucket.demo.id}"
#    source_account = "330227461796"
#  }
# }
}
resource "aws_s3_bucket_notification" "incoming" {
  bucket = aws_s3_bucket.demo.id
  lambda_function {
    lambda_function_arn = module.lambda_function_existing_package_local.lambda_function_arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.s3_permission_to_trigger_lambda]
}

resource "aws_lambda_permission" "s3_permission_to_trigger_lambda" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_function_existing_package_local.lambda_function_name
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${aws_s3_bucket.demo.id}"
}
