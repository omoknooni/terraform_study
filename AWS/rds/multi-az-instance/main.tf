# RDS 인스턴스를 Multi-AZ에 배포하는 예제
# Master DB와 Standby DB가 Multi-AZ에 배포

# VPC
module "vpc" {
  source = "../modules/vpc"
  vpc_name = "rds-test-vpc"
}

# RDS
resource "aws_db_instance" "rds_main" {
  db_name = "demoproject"
  identifier = "demo-project-db"
  skip_final_snapshot = true
  engine = var.rds_engine
  engine_version = var.rds_engine_version
  instance_class = "db.t3.micro"
  allocated_storage = 20

  username = var.rds_username
  password = var.rds_password

  # multi_az를 활성화 시, 연결된 subnet group에 있는 모든 AZ에 대해 자동으로 동기식 대기 복제본을 프로비저닝
  multi_az = true
  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.name

  vpc_security_group_ids = [ module.vpc.rds-sg-id ]
}

resource "aws_db_subnet_group" "rds_subnet_group" {
  name = "rds-subnet-group"
  subnet_ids = [ module.vpc.priv_subnet_ids[0], module.vpc.priv_subnet_ids[1] ]
}


# Test Instance
module "ec2" {
  source = "../modules/ec2"
  vpc_id = module.vpc.vpc_id
  subnet_id = module.vpc.pub_subnet_ids[0]
  access_ip = "${chomp(data.http.my_ip.response_body)}/32"
}

data "http" "my_ip" {
  url = "https://checkip.amazonaws.com"
}