output "alb_dns" {
    value = module.application.alb_dns
}

output "web_instance_id" {
    value = module.application.web_instance_id
}

output "was_instance_id" {
    value = module.application.was_instance_id
}