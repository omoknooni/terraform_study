provider "aws" {
  shared_config_files = [ "" ]
  shared_credentials_files = [ "" ]
  profile = ""
  region = "ap-northeast-2"
}

terraform {
    backend "s3" {
        region = "ap-northeast-2"
        bucket = "terraform-backend-omoknooni"
        key = "terraform-study/terraform.tfstate"
        dynamodb_table = "terraform-lock-omoknooni"
        profile = ""
    }
}

resource "aws_instance" "backend_test" {
    ami = "ami-02288bc8778f3166f"
    instance_type = "t2.micro"
    key_name = aws_key_pair.backend_testkeypair.key_name
}

resource "tls_private_key" "backend_testkey" {
    algorithm = "RSA"
    rsa_bits = 4096
}

resource "local_file" "backend_test" {
    content = tls_private_key.backend_testkey.private_key_pem
    filename = "backend_test.pem"
}

resource "aws_key_pair" "backend_testkeypair" {
    key_name = "backend_test"
    public_key = tls_private_key.backend_testkey.public_key_openssh
}

# resource "aws_security_group" "backend_test-sg" {
#     name = "backend_test-sg"
#     description = "backend_test-sg"

#     ingress {
#         cidr_blocks = [ "0.0.0.0/0" ]
#         from_port = 0
#         to_port = 0
#         protocol = 
#     }

#     egress {

#     }
# }