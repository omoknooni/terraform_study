output "alb_dns" {
    value = aws_alb.simple-3tier-ex-alb.dns_name
}

output "application_sg_id" {
    value = aws_security_group.simple-3tier-application-sg.id
}