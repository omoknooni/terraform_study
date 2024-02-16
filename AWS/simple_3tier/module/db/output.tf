output "master_db_address" {
    value = aws_db_instance.simple-3tier-master.address
}

output "slave_db_address" {
    value = aws_db_instance.simple-3tier-slave.address
}