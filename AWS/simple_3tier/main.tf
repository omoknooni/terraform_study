module "application" {
    source = "./module/application"

}

module "vpc" {
    source = "./module/vpc"
}

module "db" {
    source = "./module/db"
    db_name = var.db_name
    username = var.username
    rds_password = var.rds_password

    vpc_id = module.vpc.vpc_id
    db_subnet_id = module.vpc.db_subnet_id
}