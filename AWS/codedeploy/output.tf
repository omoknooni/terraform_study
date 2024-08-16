output "ec2_IP" {
  value = aws_instance.cicd-target.public_ip
}