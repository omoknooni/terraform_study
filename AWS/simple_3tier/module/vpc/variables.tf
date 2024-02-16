variable "vpc_cidr" {
    default = "192.168.0.0/16"
}

variable "subnet_cidr" {
    default = "192.168.x.0/24"
}

variable "availability_zone_list" {
    type = list(string)
    default = [ "ap-northeast-2a", "ap-northeast-2c" ]
}