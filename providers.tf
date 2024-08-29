provider "aws" {
    region = "${var.AWS_REGION}"
    # access_key = "${var.ACCESS_KEY}"
    # secret_key = "${var.SECRET_KEY}"
}
terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
  }
}