# EC2 Instance
resource "aws_instance" "rds-test-instance" {
  ami           = data.aws_ami.ubuntu-2204.id
  instance_type = "t3.micro"
  key_name      = aws_key_pair.instance-key.key_name
  subnet_id     = var.subnet_id
  vpc_security_group_ids = [aws_security_group.sg.id]
  associate_public_ip_address = true

  user_data = <<-EOF
    #!/bin/bash
    sudo apt update
    apt install mysql-client -y
  EOF
  tags = {
    Name = "RDS-test-instance"
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

# Key pair
resource "tls_private_key" "instance-key" {
    algorithm = "RSA"
    rsa_bits = 4096
}

resource "aws_key_pair" "instance-key" {
    key_name = "instance-key"
    public_key = tls_private_key.instance-key.public_key_openssh
}

resource "local_file" "instance-key" {
    content = tls_private_key.instance-key.private_key_pem
    filename = "instance-key.pem"
}

# SG
resource "aws_security_group" "sg" {
  name        = "sg"
  description = "SG for instance to check RDS"
  vpc_id      = var.vpc_id

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = [var.access_ip]
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