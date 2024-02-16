output "vpc_id" {
    value = aws_vpc.simple-3tier-vpc.id
}

output "public_subnet_id" {
    value = aws_subnet.simple-3tier-public-subnet.*.id
}

output "application_subnet_id" {
    value = aws_subnet.simple-3tier-application-subnet.*.id
}

output "db_subnet_id" {
    value = aws_subnet.simple-3tier-db-subnet.*.id
}