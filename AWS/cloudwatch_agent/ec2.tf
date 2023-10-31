resource "aws_instance" "cloudwatchagent_demo" {
    ami = "ami-0c94855ba95c71c99"
    instance_type = "t2.micro"
    key_name = aws_key_pair.cw_demokeypair.key_name
    
    iam_instance_profile = aws_iam_instance_profile.cwagent_profile.name
    user_data = "${file("install_cw_agent.sh")}"

    subnet_id = aws_subnet.tf_study_subnet-public1.id
    vpc_security_group_ids = [ aws_security_group.cloudwatchagent_demo-sg.id ]
}

resource "aws_iam_instance_profile" "cwagent_profile" {
    name = "cwagent_profile"
    role = aws_iam_role.cw_log_role.name
}

resource "aws_security_group" "cloudwatchagent_demo-sg" {
    name = "cloudwatchagent_demo-sg"
    description = "cloudwatchagent_demo-sg"
    vpc_id = aws_vpc.tf_study_vpc.id
    
    ingress {
        cidr_blocks = [ "0.0.0.0/0" ]
        description = "SSH"
        from_port = 22
        to_port = 22
        protocol = "tcp"
    }

    egress {
        cidr_blocks = [ "0.0.0.0/0" ]
        from_port = 0
        to_port = 0
        protocol = "-1"
    }
}

resource "tls_private_key" "cloudwatchagent_demokey" {
    algorithm = "RSA"
    rsa_bits = 4096
}

resource "aws_key_pair" "cw_demokeypair" {
    key_name = "cw_demokey"
    public_key = tls_private_key.cloudwatchagent_demokey.public_key_openssh
}

resource "local_file" "cw_demokey" {
    content = tls_private_key.cloudwatchagnet_demokey.private_key_pem
    filename = "cw_demokey.pem"
}