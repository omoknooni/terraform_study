output "vpc_id" {
  value = aws_vpc.rds_test_vpc.id
}

output "pub_subnet_ids" {
  value = aws_subnet.rds-test-pub.*.id
}

output "priv_subnet_ids" {
  value = aws_subnet.rds-test-priv.*.id
}

output "rds-sg-id" {
  value = aws_security_group.rds-sg.id
}