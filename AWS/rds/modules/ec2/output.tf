output "instance_public_ip" {
  value = aws_instance.rds-test-instance.public_ip
}