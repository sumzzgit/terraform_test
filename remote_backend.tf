# //fetch the s3 bucket name 
# data "aws_s3_bucket" "s3_bucket"{
#     bucket = "sumzzbucket1"
# }

terraform {
  backend "s3" {
    bucket = "sumzzbucket1"
    key = "terraform/terraform.tfstate"
    region = "ap-south-1"
    dynamodb_table = "terraform-statelocking"
  }
  
}