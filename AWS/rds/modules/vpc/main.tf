resource "aws_vpc" "rds_test_vpc" {
  cidr_block = "172.18.0.0/16"

  tags = {
    Name = var.vpc_name
  }
}

resource "aws_subnet" "rds-test-pub" {
  count = 2
  vpc_id = aws_vpc.rds_test_vpc.id

  cidr_block = "172.18.${count.index + 1}.0/24"
  # cidr_block = element(["172.18.1.0/24", "172.18.2.0/24"], count.index)
  availability_zone = element(["ap-northeast-2a", "ap-northeast-2c"], count.index)

  tags = {
    Name = "rds-test-pub${count.index + 1}"
  }
}

resource "aws_subnet" "rds-test-priv" {
  count = 2
  vpc_id = aws_vpc.rds_test_vpc.id

  cidr_block = "172.18.${count.index + 3}.0/24"
  availability_zone = element(["ap-northeast-2a", "ap-northeast-2c"], count.index)

  tags = {
    Name = "rds-test-priv${count.index + 1}"
  }
}

resource "aws_internet_gateway" "rds_test_igw" {
  vpc_id = aws_vpc.rds_test_vpc.id

  tags = {
    Name = "rds-test-igw"
  }
}

resource "aws_route_table" "rds-test-pub" {
  vpc_id = aws_vpc.rds_test_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.rds_test_igw.id
  }

  tags = {
    Name = "rds-test-pub"
  }
}

resource "aws_route_table" "rds-test-priv" {
  vpc_id = aws_vpc.rds_test_vpc.id

  tags = {
    Name = "rds-test-priv"
  }
}

resource "aws_route_table_association" "rds-test-pub" {
  count = 2
  subnet_id = aws_subnet.rds-test-pub[count.index].id
  route_table_id = aws_route_table.rds-test-pub.id
}

resource "aws_route_table_association" "rds-test-priv" {
  count = 2
  subnet_id = aws_subnet.rds-test-priv[count.index].id
  route_table_id = aws_route_table.rds-test-priv.id
}

resource "aws_security_group" "rds-sg" {
  name = "rds-sg"
  vpc_id = aws_vpc.rds_test_vpc.id

  ingress {
    from_port = 3306
    protocol = "tcp"
    to_port = 3306
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds-sg"
  }
}