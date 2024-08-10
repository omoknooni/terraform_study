variable "subnet_id" {
  description = "Subnet ID for instance (public)"
}

variable "vpc_id" {
  description = "VPC ID for instance"
}

variable "access_ip" {
  description = "Public IP for access instance (cidr format)"
}

variable "key_name" {
  description = "Key name for access instance"
}