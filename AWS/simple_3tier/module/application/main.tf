# Instance
resource "aws_instance" "simple-3tier-web" {
    count = 2
    ami = var.instance_ami
    instance_type = "t2.micro"
    subnet_id = element(var.application_subnet_id, count.index)

    user_data = filebase64("${path.module}/script/install_nginx.sh")

    key_name = aws_key_pair.simple-3tier-key.key_name
    vpc_security_group_ids = [ aws_security_group.simple-3tier-application-sg.id ]
}


resource "aws_instance" "simple-3tier-was" {
    count = 2
    ami = var.instance_ami
    instance_type = "t2.micro"
    subnet_id = element(var.application_subnet_id, 2+count.index)
    
    user_data = filebase64("${path.module}/script/install_tomcat.sh")

    key_name = aws_key_pair.simple-3tier-key.key_name
    vpc_security_group_ids = [ aws_security_group.simple-3tier-application-sg.id ]
}


# Security group
resource "aws_security_group" "simple-3tier-alb-sg" {
    name = "simple-3tier-alb-sg"
    vpc_id = var.vpc_id
    
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = [ "0.0.0.0/0" ]
    }
    ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = [ "0.0.0.0/0" ]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = [ "0.0.0.0/0" ]
    }
}

resource "aws_security_group" "simple-3tier-application-sg" {
    name = "simple-3tier-application-sg"
    vpc_id = var.vpc_id

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        description = "HTTP from ALB"
        security_groups = [ aws_security_group.simple-3tier-alb-sg.id ]
    }
    ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        description = "HTTPS from ALB"
        security_groups = [ aws_security_group.simple-3tier-alb-sg.id ]
    }
    ingress {
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        description = "WAS access"
        cidr_blocks = [ "0.0.0.0/0" ]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = [ "0.0.0.0/0" ]
    }
}

# Key pair
resource "tls_private_key" "simple-3tier-key" {
    algorithm = "RSA"
    rsa_bits = 4096
}

resource "aws_key_pair" "simple-3tier-key" {
    key_name = "simple-3tier-key"
    public_key = tls_private_key.simple-3tier-key.public_key_openssh
}

resource "local_file" "simple-3tier-key" {
    content = tls_private_key.simple-3tier-key.private_key_pem
    filename = "simple-3tier-key.pem"
}


### External ALB
resource "aws_alb" "simple-3tier-ex-alb" {
    name = "simple-3tier-ex-alb"
    internal = false
    load_balancer_type = "application"
    security_groups = [ aws_security_group.simple-3tier-alb-sg.id ]
    subnets = var.public_subnet_id
}

resource "aws_alb_target_group" "simple-3tier-ex-tg" {
    name = "simple-3tier-ex-tg"
    port = 80
    protocol = "HTTP"
    vpc_id = var.vpc_id
}

resource "aws_alb_target_group_attachment" "simple-3tier-ex-attach" {
    count = 2
    target_group_arn = aws_alb_target_group.simple-3tier-ex-tg.arn
    target_id = element(aws_instance.simple-3tier-web.*.id, count.index)
    port = 80
}

resource "aws_alb_listener" "simple-3tier-ex-listener" {
    load_balancer_arn = aws_alb.simple-3tier-ex-alb.arn
    port = "80"
    protocol = "HTTP"

    default_action {
      type = "forward"
      target_group_arn = aws_alb_target_group.simple-3tier-ex-tg.arn
    }
}

### Internal ALB
resource "aws_alb" "simple-3tier-inner-alb" {
    name = "simple-3tier-inner-alb"
    internal = true
    load_balancer_type = "application"
    security_groups = [ aws_security_group.simple-3tier-alb-sg.id ]
}

resource "aws_alb_target_group" "simple-3tier-inner-tg" { 
    name = "simple-3tier-inner-tg"
    port = 8080
    protocol = "HTTP"
    vpc_id = var.vpc_id
}

resource "aws_alb_target_group_attachment" "simple-3tier-inner-attach" {
    count = 2
    target_group_arn = aws_alb_target_group.simple-3tier-inner-tg.arn
    target_id = element(aws_instance.simple-3tier-was.*.id, count.index)
    port = 8080
}

resource "aws_alb_listener" "simple-3tier-inner-listener" {
    load_balancer_arn = aws_alb.simple-3tier-inner-alb.arn
    port = "8080"
    protocol = "HTTP"

    default_action {
      type = "forward"
      target_group_arn = aws_alb_target_group.simple-3tier-inner-tg.arn
    }
}

