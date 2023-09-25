# EC2
resource "aws_instance" "tf_study_instance1" {
  ami = "ami-02288bc8778f3166f"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.tf_study_subnet-private1.id
  key_name = aws_key_pair.tf_study_key.key_name
  vpc_security_group_ids = [ aws_security_group.tf_study-instance-sg.id ]
}

resource "aws_instance" "tf_study_instance2" {
  ami = "ami-0c9c942bd7bf113a2"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.tf_study_subnet-private2.id
  key_name = aws_key_pair.tf_study_key.key_name
  vpc_security_group_ids = [ aws_security_group.tf_study-instance-sg.id ]
}

# key pair
resource "aws_key_pair" "tf_study_key" {
  key_name = "tf_study_key"
  public_key = file("./tf_study.pub")
}

# Security Group
resource "aws_security_group" "tf_study-instance-sg" {
  name = "instance-sg"
  description = "HTTP from ALB"
  vpc_id = aws_vpc.tf_study_vpc.id

  ingress {
    cidr_blocks = null
    description = "HTTP from ALB"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    security_groups = [ aws_security_group.tf_study-alb-sg.id ]
  }

  egress {
    cidr_blocks = [ "0.0.0.0/0" ]
    from_port = 0
    to_port = 0
    protocol = "-1"
  }
}

resource "aws_security_group" "tf_study-alb-sg" {
  name = "tf_study-alb-sg"
  description = "ALB HTTP ALLOW"
  vpc_id = aws_vpc.tf_study_vpc.id

  ingress {
    cidr_blocks = [ "0.0.0.0/0" ]
    from_port = 80
    to_port = 80
    protocol = "tcp"
  }

  egress {
    cidr_blocks = [ "0.0.0.0/0" ]
    from_port = 0
    to_port = 0
    protocol = "-1"
  }
}

# ALB
resource "aws_alb" "tf_study_alb" {
  name = "tf-study-alb"
  internal = false
  load_balancer_type = "application"
  security_groups = [ aws_security_group.tf_study-alb-sg.id ]
  subnets = [ aws_subnet.tf_study_subnet-public1.id, aws_subnet.tf_study_subnet-public2.id ]
}

# Target group
resource "aws_alb_target_group" "tf_study-target-group" {
  name = "tf-study-target-group"
  vpc_id = aws_vpc.tf_study_vpc.id
  port = 80
  protocol = "HTTP"
}

# Target group associate
resource "aws_alb_target_group_attachment" "private1_ec2_attach" {
  target_group_arn = aws_alb_target_group.tf_study-target-group.id
  target_id = aws_instance.tf_study_instance1.id
  port = 80
}

resource "aws_alb_target_group_attachment" "private2_ec2_attach" {
  target_group_arn = aws_alb_target_group.tf_study-target-group.id
  target_id = aws_instance.tf_study_instance2.id
  port = 80
}

# ALB Listener
resource "aws_alb_listener" "name" {
  load_balancer_arn = aws_alb.tf_study_alb.arn
  port = 80
  protocol = "HTTP"
  default_action {
    type = "forward"
    target_group_arn = aws_alb_target_group.tf_study-target-group.arn
  }
}