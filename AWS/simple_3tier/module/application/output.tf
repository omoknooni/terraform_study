output "alb_dns" {
    value = aws_alb.simple-3tier-ex-alb.dns_name
}

output "application_sg_id" {
    value = aws_security_group.simple-3tier-application-sg.id
}

output "web_instance_id" {
    value = aws_instance.simple-3tier-web.*.id
}

output "was_instance_id" {
    value = aws_instance.simple-3tier-was.*.id
}