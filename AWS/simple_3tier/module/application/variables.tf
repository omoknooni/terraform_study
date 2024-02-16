variable "vpc_id" {}

variable "application_subnet_id" {
    type = list(string)
}

variable "instance_ami" {}