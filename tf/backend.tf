terraform {
  backend "s3" {
    bucket         = "jasmit-tf-state-bucket"
    key           = "aws-cost-reporter/terraform.state.tfstate"
    region        = "us-east-1"
    encrypt       = true
  }
}
