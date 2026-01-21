terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  alias   = "singapore"
  region  = "ap-southeast-1"
  profile = var.aws_profile
}
