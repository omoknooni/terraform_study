terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~> 5.0"
    }
  }
}

provider "aws" {
    region = "us-east-2"
    shared_config_files = [ "" ]
    shared_credentials_files = [ "" ]
    profile = ""
}