# EC2 Instance
resource "aws_instance" "network-test-instance" {
  ami           = data.aws_ami.ubuntu-2204.id
  instance_type = "t3.micro"
  key_name      = var.key_name
  subnet_id     = var.subnet_id
  vpc_security_group_ids = [aws_security_group.sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "network-connect-test-instance"
  }
}

data "aws_ami" "ubuntu-2204" {
  most_recent = true
  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical
}

# SG
resource "aws_security_group" "sg" {
  name        = "sg"
  description = "SG for instance to check network connection"
  vpc_id      = var.vpc_id

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = [var.access_ip]
  }

  ingress {
    from_port = -1
    to_port   = -1
    protocol = "ICMP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg"
  }
}