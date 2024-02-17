resource "aws_db_instance" "simple-3tier-master" {
    allocated_storage = 8
    db_name = "${var.db_name}Master"
    username = var.username
    password = var.rds_password

    instance_class = "db.t3.micro"
    engine = "mysql"
    engine_version = "8.0.35"

    availability_zone = var.availability_zone_list[0]
    db_subnet_group_name = aws_db_subnet_group.simple-3tier-db-subnet-group.name
    vpc_security_group_ids = [aws_security_group.simple-3tier-rds-sg.id]
}

resource "aws_db_instance" "simple-3tier-slave" {
    allocated_storage = 8
    db_name = "${var.db_name}Slave"
    username = var.username
    password = var.rds_password

    replicate_source_db = aws_db_instance.simple-3tier-master.id

    instance_class = "db.t3.micro"
    engine = "mysql"
    engine_version = "8.0.35"

    availability_zone = var.availability_zone_list[1]
    db_subnet_group_name = aws_db_subnet_group.simple-3tier-db-subnet-group.name
    vpc_security_group_ids = [ aws_security_group.simple-3tier-rds-sg.id ]
}


resource "aws_security_group" "simple-3tier-rds-sg" {
    name = "simple-3tier-rds-sg"
    vpc_id = var.vpc_id

    ingress {
        from_port = 3306
        to_port = 3306
        protocol = "tcp"
        description = "DB Access from application(was)"
        security_groups = [ var.application_sgid ]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = [ "0.0.0.0/0" ]
    }
}

resource "aws_db_subnet_group" "simple-3tier-db-subnet-group" {
    name = "simple-3tier-db-subnet-group"
    subnet_ids = var.db_subnet_id
}