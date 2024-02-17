resource "aws_vpc" "simple-3tier-vpc" {
    cidr_block = var.vpc_cidr
    enable_dns_hostnames = true
    enable_dns_support = true
}

# subnet
resource "aws_subnet" "simple-3tier-public-subnet" {
    count = 2
    vpc_id = aws_vpc.simple-3tier-vpc.id
    cidr_block = replace(var.subnet_cidr, "x", 1 + count.index) # 192.168.1.0/24, 192.168.2.0/24
    availability_zone = element(var.availability_zone_list, count.index)
}

resource "aws_subnet" "simple-3tier-application-subnet" {
    count = 4
    vpc_id = aws_vpc.simple-3tier-vpc.id
    cidr_block = replace(var.subnet_cidr, "x", 3 + count.index) # 192.168.3.0/24, 192.168.4.0/24, 192.168.5.0/24, 192.168.6.0/24
    availability_zone = element(var.availability_zone_list, count.index)
}

resource "aws_subnet" "simple-3tier-db-subnet" {
    count = 2
    vpc_id = aws_vpc.simple-3tier-vpc.id
    cidr_block = replace(var.subnet_cidr, "x", 7 + count.index) # 192.168.7.0/24, 192.168.8.0/24
    availability_zone = element(var.availability_zone_list, count.index)
}

# Route Table
resource "aws_route_table" "simple-3tier-pub-rt" {
    vpc_id = aws_vpc.simple-3tier-vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.simple-3tier-igw.id
    }
}

resource "aws_route_table" "simple-3tier-priv-rt" {
    vpc_id = aws_vpc.simple-3tier-vpc.id
}

# Route table Associate
resource "aws_route_table_association" "simple-3tier-pub-asso" {
    count = 2
    subnet_id = aws_subnet.simple-3tier-public-subnet.*.id[count.index]
    route_table_id = aws_route_table.simple-3tier-pub-rt.id
}

resource "aws_route_table_association" "simple-3tier-application-asso" {
    count = 4
    subnet_id = aws_subnet.simple-3tier-application-subnet.*.id[count.index]
    route_table_id = aws_route_table.simple-3tier-priv-rt.id
}

resource "aws_route_table_association" "simple-3tier-db-asso" {
    count = 2
    subnet_id = aws_subnet.simple-3tier-db-subnet.*.id[count.index]
    route_table_id = aws_route_table.simple-3tier-priv-rt.id
}

# IGW
resource "aws_internet_gateway" "simple-3tier-igw" {
    vpc_id = aws_vpc.simple-3tier-vpc.id
}


# NAT GW - EIP
resource "aws_eip" "simple-3tier-natgw-eip" {
    domain = "vpc"
}

# NAT GW - natgw
resource "aws_nat_gateway" "simple-3tier-natgw" {
    allocation_id = aws_eip.simple-3tier-natgw-eip.id
    subnet_id = aws_subnet.simple-3tier-public-subnet.*.id[1]
}
