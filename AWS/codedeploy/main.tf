data "aws_ami" "ubuntu2204" {
  owners      = ["099720109477"]
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
data "http" "my-ip" {
  url = "https://checkip.amazonaws.com"
}
# Target Instance
resource "aws_instance" "cicd-target" {
  ami = data.aws_ami.ubuntu2204.id
  instance_type = "t3a.small"
  key_name = aws_key_pair.instance-key.key_name
  subnet_id = var.subnet_id
  vpc_security_group_ids = [ aws_security_group.cicd-target-sg.id ]
  associate_public_ip_address = true
  iam_instance_profile = aws_iam_instance_profile.ec2-profile.name
  user_data = file("init-script.sh")

  tags = {
    Name="cicd-target"
  }
}

resource "aws_security_group" "cicd-target-sg" {
  name = "cicd-target-sg"
  description = "SG for cicd-target"
  vpc_id = var.vpc_id
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["${chomp(data.http.my-ip.response_body)}/32"]
  }
  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["${chomp(data.http.my-ip.response_body)}/32"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "cicd-target-sg"
  }
}

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

# S3 Bucket
resource "aws_s3_bucket" "cicd-bucket" {
  bucket = "omoknooni-codedeploy"
  force_destroy = true
}

# CodeDeploy
resource "aws_codedeploy_app" "cd-app" {
  name = "cd-app"
}

resource "aws_codedeploy_deployment_group" "cd-group" {
  app_name = aws_codedeploy_app.cd-app.name
  deployment_config_name = "CodeDeployDefault.AllAtOnce"
  deployment_group_name = "cd-group"
  service_role_arn = aws_iam_role.cd-role.arn

  # 대상 지정, EC2 태그로 지정해줌
  ec2_tag_set {
    ec2_tag_filter {
      key = "Name"
      value = "cicd-target"
      type = "KEY_AND_VALUE"
    }
  }
}

# IAM Role for CodeDeploy
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codedeploy.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "cd-role" {
  name               = "cd-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "AWSCodeDeployRole" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
  role       = aws_iam_role.cd-role.name
}

# IAM Role for EC2 to access S3
data "aws_iam_policy_document" "ec2-assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}
resource "aws_iam_role" "ec2-role" {
  name               = "ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2-assume_role.json
}
resource "aws_iam_role_policy_attachment" "ec2-role-attach" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforAWSCodeDeploy"
  role       = aws_iam_role.ec2-role.name
}
resource "aws_iam_instance_profile" "ec2-profile" {
  name = "ec2-profile"
  role = aws_iam_role.ec2-role.name
}