output "ec2_public_ips" {
  value = {
    "seoul" = module.ec2-seoul.instance_public_ip,
    "osaka" = module.ec2-osaka.instance_public_ip
  }
}

output "ec2_private_ips" {
  value = {
    "seoul" = module.ec2-seoul.instance_private_ip,
    "osaka" = module.ec2-osaka.instance_private_ip
  }
}