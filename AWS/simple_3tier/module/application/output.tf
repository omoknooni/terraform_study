output "alb_dns" {
    value = aws_alb.simple-3tier-ex-alb.dns_name
}