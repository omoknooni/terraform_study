output "rds_endpoint" {
  value = aws_db_instance.rds_main.endpoint
}

output "rds_az" {
  value = aws_db_instance.rds_main.availability_zone
}

output "rds_username" {
  value = aws_db_instance.rds_main.username
}

output "ec2-instance-public_ip" {
  value = module.ec2.instance_public_ip
}