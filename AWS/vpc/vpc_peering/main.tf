# VPC Peering with different region

# VPC - Seoul
resource "aws_vpc" "seoul" {
  cidr_block = "172.10.0.0/16"

  tags = {
    Name = "peering-seoul"
  }
}

resource "aws_subnet" "seoul_pub" {
  vpc_id = aws_vpc.seoul.id
  cidr_block = "172.10.1.0/24"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "seoul-public-subnet"
  }
}

resource "aws_internet_gateway" "seoul_igw" {
  vpc_id = aws_vpc.seoul.id

  tags = {
    Name = "seoul-internet-gateway"
  }
}

resource "aws_route_table" "seoul_pub_rt" {
  vpc_id = aws_vpc.seoul.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.seoul_igw.id
  }

  route {
    cidr_block = "192.168.0.0/16"
    vpc_peering_connection_id = aws_vpc_peering_connection.peering.id
  }

  tags = {
    Name = "seoul-public-route-table"
  }
}
resource "aws_route_table_association" "seoul_pub" {
  subnet_id = aws_subnet.seoul_pub.id
  route_table_id = aws_route_table.seoul_pub_rt.id
}

# VPC - Osaka
resource "aws_vpc" "osaka" {
  provider = aws.osaka
  cidr_block = "192.168.0.0/16"

  tags = {
    Name = "peering-osaka"
  }
}

resource "aws_subnet" "osaka_pub" {
  provider = aws.osaka
  vpc_id = aws_vpc.osaka.id
  cidr_block = "192.168.1.0/24"
  availability_zone = "ap-northeast-3a"

  tags = {
    Name = "osaka-public-subnet"
  }
}

resource "aws_internet_gateway" "osaka_igw" {
  provider = aws.osaka
  vpc_id = aws_vpc.osaka.id

  tags = {
    Name = "osaka-internet-gateway"
  }
}

resource "aws_route_table" "osaka_pub_rt" {
  provider = aws.osaka
  vpc_id = aws_vpc.osaka.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.osaka_igw.id
  }

  route {
    cidr_block = "172.10.0.0/16"
    vpc_peering_connection_id = aws_vpc_peering_connection.peering.id
  }
}

resource "aws_route_table_association" "osaka_pub" {
  provider = aws.osaka
  subnet_id = aws_subnet.osaka_pub.id
  route_table_id = aws_route_table.osaka_pub_rt.id
}

data "http" "my_ip" {
  url = "https://checkip.amazonaws.com"
}

# Instance
module "ec2-seoul" {
  source = "../module/ec2"
  
  vpc_id = aws_vpc.seoul.id
  subnet_id = aws_subnet.seoul_pub.id
  access_ip = "${chomp(data.http.my_ip.response_body)}/32"
  key_name = aws_key_pair.instance-key.key_name
}

module "ec2-osaka" {
  source = "../module/ec2"
  
  vpc_id = aws_vpc.osaka.id
  subnet_id = aws_subnet.osaka_pub.id
  access_ip = "${chomp(data.http.my_ip.response_body)}/32"
  key_name = aws_key_pair.instance_key_osaka.key_name

  providers = {
    aws = aws.osaka
  }
}

# Key pair
resource "tls_private_key" "instance-key" {
    algorithm = "RSA"
    rsa_bits = 4096
}

resource "aws_key_pair" "instance-key" {
    key_name = "instance-key"
    public_key = tls_private_key.instance-key.public_key_openssh
}

resource "aws_key_pair" "instance_key_osaka" {
  key_name = "instance-key"
  public_key = tls_private_key.instance-key.public_key_openssh
  provider = aws.osaka
}

resource "local_file" "instance-key" {
    content = tls_private_key.instance-key.private_key_pem
    filename = "instance-key.pem"
}


# VPC Peering
# Requester : Seoul, Accepter : Osaka
resource "aws_vpc_peering_connection" "peering" {
  vpc_id = aws_vpc.seoul.id
  peer_vpc_id = aws_vpc.osaka.id
  peer_region = "ap-northeast-3"

  tags = {
    Name = "seoul-to-osaka"
  }
}

# Osaka쪽에서 VPC Peering Connection을 Accept해주기 위한 리소스
resource "aws_vpc_peering_connection_accepter" "peer" {
  provider = aws.osaka
  vpc_peering_connection_id = aws_vpc_peering_connection.peering.id
  auto_accept = true

  tags = {
    Side = "Accepter"
  }
}