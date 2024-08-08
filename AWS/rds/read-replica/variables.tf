variable "rds_username" {
  description = "Username of RDS"
}

variable "rds_password" {
  description = "Password for RDS"
}

variable "rds_engine" {
  description = "Engine for RDS (default: mysql)"
  default = "mysql"
}

variable "rds_engine_version" {
  description = "Engine Version of RDS (default: 8.0)"
  default = "8.0"
}