output "instance_public_ip" {
  value = aws_instance.network-test-instance.public_ip
}

output "instance_private_ip" {
  value = aws_instance.network-test-instance.private_ip
}