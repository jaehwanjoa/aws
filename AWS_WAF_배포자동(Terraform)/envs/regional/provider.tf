terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  alias   = "seoul"
  region  = "ap-northeast-2"
  profile = var.aws_profile
}
