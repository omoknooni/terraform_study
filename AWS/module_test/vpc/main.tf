resource "aws_vpc" "tf_modulestudy_vpc" {
    cidr_block = var.moduletest_vpc_cidr
}

resource "aws_subnet" "modulestudy-public-subnet" {
    vpc_id = aws_vpc.tf_modulestudy_vpc.id
    cidr_block = "192.168.10.0/26"
    availability_zone = "ap-northeast-2"
}

resource "aws_internet_gateway" "tf_modulestudy-igw" {
  vpc_id = aws_vpc.tf_modulestudy_vpc.id
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.tf_modulestudy_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.tf_modulestudy-igw.id
  }
  tags = {
    "Name" = "public_rt"
  }
}