variable "db_name" {}
variable "username" {}
variable "rds_password" {}

variable "vpc_id" {}
variable "db_subnet_id" {}

variable "application_sgid" {}

variable "availability_zone_list" {
    type = list(string)
}