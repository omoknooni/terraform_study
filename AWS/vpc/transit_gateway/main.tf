# Transit Gateway with different region

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
    transit_gateway_id = aws_ec2_transit_gateway.seoul-tgw.id
  }

  route {
    cidr_block = "192.169.0.0/16"
    transit_gateway_id = aws_ec2_transit_gateway.seoul-tgw.id
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

resource "aws_vpc" "osaka-2" {
  provider = aws.osaka
  cidr_block = "192.169.0.0/16"

  tags = {
    Name = "peering-osaka-2"
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

resource "aws_subnet" "osaka_pub_2" {
  provider = aws.osaka
  vpc_id = aws_vpc.osaka-2.id
  cidr_block = "192.169.1.0/24"
  availability_zone = "ap-northeast-3c"

  tags = {
    Name = "osaka-public-subnet-2"
  }
}

resource "aws_internet_gateway" "osaka_igw" {
  provider = aws.osaka
  vpc_id = aws_vpc.osaka.id

  tags = {
    Name = "osaka-internet-gateway"
  }
}

resource "aws_internet_gateway" "osaka_igw_2" {
  provider = aws.osaka
  vpc_id = aws_vpc.osaka-2.id

  tags = {
    Name = "osaka-internet-gateway-2"
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
    transit_gateway_id = aws_ec2_transit_gateway.osaka-tgw.id 
  }

  route {
    cidr_block = "192.169.0.0/16"
    transit_gateway_id = aws_ec2_transit_gateway.osaka-tgw.id
  }

  tags = {
    Name = "osaka-public-route-table"
  }
}

resource "aws_route_table_association" "osaka_pub" {
  provider = aws.osaka
  subnet_id = aws_subnet.osaka_pub.id
  route_table_id = aws_route_table.osaka_pub_rt.id
}

resource "aws_route_table" "osaka_pub_2_rt" {
  provider = aws.osaka
  vpc_id = aws_vpc.osaka-2.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.osaka_igw_2.id
  }

  route {
    cidr_block = "172.10.0.0/16"
    transit_gateway_id = aws_ec2_transit_gateway.osaka-tgw.id
  }

  route {
    cidr_block = "192.168.0.0/16"
    transit_gateway_id = aws_ec2_transit_gateway.osaka-tgw.id
  }

  tags = {
    Name = "osaka-public-route-table-2"
  }
}

resource "aws_route_table_association" "osaka_pub_2" {
  provider = aws.osaka
  subnet_id = aws_subnet.osaka_pub_2.id
  route_table_id = aws_route_table.osaka_pub_2_rt.id
}

data "http" "my_ip" {
  url = "https://checkip.amazonaws.com"
}

# Instance
# place instance in each VPC's subnet (seoul, osaka, osaka-2)
module "ec2-seoul" {
  source = "../module/ec2"

  vpc_id = aws_vpc.seoul.id
  subnet_id = aws_subnet.seoul_pub.id
  access_ip = "${chomp(data.http.my_ip.response_body)}/32"
  key_name = aws_key_pair.instance-key.key_name
}

module "ec2-osaka" {
  source = "../module/ec2"
  providers = {aws = aws.osaka}
  
  vpc_id = aws_vpc.osaka.id
  subnet_id = aws_subnet.osaka_pub.id
  access_ip = "${chomp(data.http.my_ip.response_body)}/32"
  key_name = aws_key_pair.instance_key_osaka.key_name
}

module "ec2-osaka-2" {
  source = "../module/ec2"
  providers = {aws = aws.osaka}
  
  vpc_id = aws_vpc.osaka-2.id
  subnet_id = aws_subnet.osaka_pub_2.id
  access_ip = "${chomp(data.http.my_ip.response_body)}/32"
  key_name = aws_key_pair.instance_key_osaka.key_name
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
  provider = aws.osaka
  key_name = "instance-key"
  public_key = tls_private_key.instance-key.public_key_openssh
}

resource "local_file" "instance-key" {
  content = tls_private_key.instance-key.private_key_pem
  filename = "instance-key.pem"
}


# Transit Gateway
resource "aws_ec2_transit_gateway" "seoul-tgw" {
  description = "Transit Gateway at seoul"
}

resource "aws_ec2_transit_gateway" "osaka-tgw" {
  provider = aws.osaka
  description = "Transit Gateway at osaka"
}

# Transit Gateway Attachment
# Transit GW에 VPC를 연결
resource "aws_ec2_transit_gateway_vpc_attachment" "seoul-tgw-attachment" {
  subnet_ids = [aws_subnet.seoul_pub.id]
  transit_gateway_id = aws_ec2_transit_gateway.seoul-tgw.id
  vpc_id = aws_vpc.seoul.id
}

resource "aws_ec2_transit_gateway_vpc_attachment" "osaka-tgw-attachment" {
  provider = aws.osaka
  subnet_ids = [ aws_subnet.osaka_pub.id ]
  transit_gateway_id = aws_ec2_transit_gateway.osaka-tgw.id
  vpc_id = aws_vpc.osaka.id
}

resource "aws_ec2_transit_gateway_vpc_attachment" "osaka-2-tgw-attachment" {
  provider = aws.osaka
  subnet_ids = [ aws_subnet.osaka_pub_2.id ]
  transit_gateway_id = aws_ec2_transit_gateway.osaka-tgw.id
  vpc_id = aws_vpc.osaka-2.id
}


# Transit Gateway Peering
# 두 리전의 Transit GW끼리 연결
resource "aws_ec2_transit_gateway_peering_attachment" "tgw-peering" {
  peer_account_id = aws_ec2_transit_gateway.osaka-tgw.owner_id
  peer_region = "ap-northeast-3"
  peer_transit_gateway_id = aws_ec2_transit_gateway.osaka-tgw.id
  transit_gateway_id = aws_ec2_transit_gateway.seoul-tgw.id
}

# Transit Gateway Peering Accepter
# peer 연결을 받을 Osaka에서 Accept 처리
resource "aws_ec2_transit_gateway_peering_attachment_accepter" "osaka-tgw-peering" {
  provider = aws.osaka
  transit_gateway_attachment_id = aws_ec2_transit_gateway_peering_attachment.tgw-peering.id
}

# Transit Gateway Route
# 서울 <-> 오사카 라우트 지정 필요 (리전을 넘어가는 peering을 생성했기에)
# transit_gateway_attachment_id : peering을 타고 트래픽이 넘어가야하므로 vpc_attachment가 아닌 peering attachment
# transit_gateway_route_table_id : TGW routing table은 별도로 만들어 주지 않았으므로 기본 routing table을 지정
resource "aws_ec2_transit_gateway_route" "seoul-to-osaka" {
  destination_cidr_block = "192.168.0.0/16"
  transit_gateway_attachment_id = aws_ec2_transit_gateway_peering_attachment.tgw-peering.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway.seoul-tgw.association_default_route_table_id
}

resource "aws_ec2_transit_gateway_route" "seoul-to-osaka-2" {
  destination_cidr_block = "192.169.0.0/16"
  transit_gateway_attachment_id = aws_ec2_transit_gateway_vpc_attachment.seoul-tgw-attachment.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway.seoul-tgw.association_default_route_table_id
}

resource "aws_ec2_transit_gateway_route" "osaka-to-seoul" {
  provider = aws.osaka
  destination_cidr_block = "172.10.0.0/16"
  transit_gateway_attachment_id = aws_ec2_transit_gateway_peering_attachment.tgw-peering.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway.osaka-tgw.association_default_route_table_id
}