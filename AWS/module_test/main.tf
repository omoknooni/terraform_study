provider "aws" {
    shared_config_files = [ "" ] 
    shared_credentials_files = [ "" ]
    profile = ""
    region = "ap-northeast-2"  
}

module "tf_test_vpc" {
  source  = "./vpc"
  moduletest_vpc_cidr = "192.168.11.0/24"
}
