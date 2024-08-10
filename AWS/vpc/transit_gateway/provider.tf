provider "aws" {
  region = "ap-northeast-2"
  shared_config_files = [ "~/.aws/config" ]
  shared_credentials_files = [ "~/.aws/credentials" ]
  profile = "hyeok"
}

provider "aws" {
  region = "ap-northeast-3"
  alias = "osaka"
  shared_config_files = [ "~/.aws/config" ]
  shared_credentials_files = [ "~/.aws/credentials" ]
  profile = "hyeok"
}