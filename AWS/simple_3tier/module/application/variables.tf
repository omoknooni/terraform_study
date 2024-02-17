variable "vpc_id" {}
variable "public_subnet_id" {
    type = list(string)
}
variable "application_subnet_id" {
    type = list(string)
}

variable "instance_ami" {}
variable "eice_sg_id" {}