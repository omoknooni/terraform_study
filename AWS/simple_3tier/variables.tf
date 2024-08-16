# AZ
variable "availability_zone_list" {
    type = list(string)
    default = [ "ap-northeast-2a", "ap-northeast-2c" ]
}

# Application
variable "instance_ami" {
    default = "ami-0f3a440bbcff3d043"
}

# VPC
variable "vpc_cidr" {
    default = "192.168.0.0/16"
}
variable "subnet_cidr" {
    default = "192.168.x.0/24"
}

# DB
variable "db_name" {
    default = "Simple3tierDB"
}
variable "username" {
    default = "simplemaster"
}
variable "rds_password" {}