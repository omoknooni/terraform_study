output "rds_main-endpoint" {
  value = aws_db_instance.rds_main.endpoint
}

output "rds_replica-endpoint" {
  value = aws_db_instance.rds_replica.endpoint
}

output "rds_main-az" {
  value = aws_db_instance.rds_main.availability_zone
}

output "rds_replica-az" {
  value = aws_db_instance.rds_replica.availability_zone
}

output "rds_username" {
  value = aws_db_instance.rds_main.username
}

output "ec2-instance-public_ip" {
  value = module.ec2.instance_public_ip
}