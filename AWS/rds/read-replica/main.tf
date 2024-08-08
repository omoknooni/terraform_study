# RDS의 Read-Replica를 생성하는 예제
# Master DB와 그 Replica DB를 다른 AZ에 배포
module "vpc" {
  source = "../modules/vpc"
  vpc_name = "rds-rp-test-vpc"
}

# RDS
resource "aws_db_instance" "rds_main" {
  db_name = "rpmain"
  identifier = "rp-main"
  engine = var.rds_engine
  engine_version = var.rds_engine_version
  instance_class = "db.t3.micro"
  allocated_storage = 20

  username = var.rds_username
  password = var.rds_password

  availability_zone = "ap-northeast-2a"
  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [ module.vpc.rds-sg-id ]

  skip_final_snapshot = true

  # Must be greater then 0 if the database is used as a source for a Read Replica
  backup_retention_period = 7
}

resource "aws_db_instance" "rds_replica" {
  # Specfies that this resource is a replica of another RDS instance
  replicate_source_db = aws_db_instance.rds_main.identifier
  skip_final_snapshot = true

  identifier = "rp-replica"
  engine = var.rds_engine
  engine_version = var.rds_engine_version
  instance_class = "db.t3.micro"
  allocated_storage = 20

  password = var.rds_password

  availability_zone = "ap-northeast-2c"
  # db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.name
}

resource "aws_db_subnet_group" "rds_subnet_group" {
  name = "rds-subnet-group"
  subnet_ids = [ module.vpc.priv_subnet_ids[0], module.vpc.priv_subnet_ids[1]]
}

module "ec2" {
  source = "../modules/ec2"
  vpc_id = module.vpc.vpc_id
  subnet_id = module.vpc.pub_subnet_ids[0]
  access_ip = "${chomp(data.http.my_ip.response_body)}/32"
}

data "http" "my_ip" {
  url = "https://checkip.amazonaws.com"
}