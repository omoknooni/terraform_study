resource "aws_db_instance" "simple-3tier-master" {
    allocated_storage = 8
    db_name = var.db_name
    username = var.username
    password = var.rds_password

    instance_class = "db.t3.micro"
    engine = "mysql"
    engine_version = "8.0.35"

    availability_zone = var.availability_zone_list[0]
    db_subnet_group_name = aws_db_subnet_group.simple-3tier-db-subnet-group.*.name[0]
}

resource "aws_db_instance" "simple-3tier-slave" {
    allocated_storage = 8
    db_name = var.db_name
    username = var.username
    password = var.rds_password

    instance_class = "db.t3.micro"
    engine = "mysql"
    engine_version = "8.0.35"

    availability_zone = var.availability_zone_list[1]
    db_subnet_group_name = aws_db_subnet_group.simple-3tier-db-subnet-group.*.name[1]
}


resource "aws_security_group" "simple-3tier-rds-sg" {
    name = "simple-3tier-rds-sg"
    vpc_id = var.vpc_id

    ingress {
        from_port = 3306
        to_port = 3306
        description = "DB Access from application(was)"
        security_groups = [ var.application_sgid ]
    }
}

resource "aws_db_subnet_group" "simple-3tier-db-subnet-group" {
    count = 2
    name = "simple-3tier-db-subnet-group"
    subnet_ids = var.db_subnet_id[count.index]
}