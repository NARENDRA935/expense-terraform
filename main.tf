/*
module "vpc" {
  source              = "./module/vpc"
  for_each            = var.vpc
  vpc_cidr            = lookup(each.value,"vpc_cidr",null)
  public_subnets_cidr = lookup(each.value,"public_subnets_cidr",null )
  web_subnets_cidr    = lookup(each.value,"web_subnets_cidr",null )
  app_subnets_cidr    = lookup(each.value,"app_subnets_cidr",null )
  db_subnets_cidr     = lookup(each.value,"db_subnets_cidr",null )
  az                  = lookup(each.value, "az",null )

  env                 = var.env
  project_name        = var.project_name
}

module "rds" {
  source = "./module/rds"
  for_each             = var.rds

## varible of rds
  allocated_storage    = lookup(each.value,"allocated_storage",null)
  db_name              = lookup(each.value,"db_name",null)
  engine               = lookup(each.value,"engine",null)
  engine_version       = lookup(each.value,"engine_version",null)
  instance_class       = lookup(each.value,"instance_class",null)
  family               = lookup(each.value,"family",null)

 ##common varibles
  env                 = var.env
  project_name        = var.project_name
  kms_key_id          = var.kms_key_id

##other varibles like outputs
  subnet_ids  = lookup(lookup(module.vpc,"main",null ), "db_subnet_ids",null)
  vpc_id      = lookup(lookup(module.vpc,"main",null ), "vpc_id",null)
  sg_cidr_blocks = lookup(lookup(var.vpc,"main",null ), "app_subnets_cidr",null)
}*/

#network
module "vpc" {
  source              = "./module/vpc"
  vpc_cidr            = var.vpc_cidr
  public_subnets_cidr = var.public_subnets_cidr
  web_subnets_cidr    = var.web_subnets_cidr
  app_subnets_cidr    = var.app_subnets_cidr
  db_subnets_cidr     = var.db_subnets_cidr
  az                  = var. az

  env                 = var.env
  project_name        = var.project_name
}

#database
module "rds" {
  source = "./module/rds"


  ## varible of rds
  allocated_storage    = var.rds_allocated_storage
  db_name              = var.rds_db_name
  engine               = var.rds_engine
  engine_version       =var.rds_engine_version
  instance_class       = var.rds_instance_class
  family               = var.rds_family

  ##common varibles
  env                 = var.env
  project_name        = var.project_name
  kms_key_id          = var.kms_key_id

  ##other varibles like outputs
  subnet_ids  = module.vpc.app_subnets_ids
  vpc_id      = module.vpc.vpc_id
  sg_cidr_blocks = var.app_subnets_cidr
}

#application layer

module "backend" {
  source = "./module/app"

  app_port            = var.backend_app_port
  bastion_cidrs       = var.bastion_cidrs
  component           = "backend"
  env                 = var.env
  instance_capacity   = var.backend_instance_capacity
  instance_type       = var.backend_instance_type
  project_name        = var.project_name
  sg_cidr_blocks      = var.web_subnets_cidr #this needs to be checked
  vpc_id              = module.vpc.vpc_id
  vpc_zone_identifier = module.vpc.app_subnets_ids
}
#web layer
module "frontend" {
  source = "./module/app"

  app_port            = var.frontend_app_port
  bastion_cidrs       = var.bastion_cidrs
  component           = "frontend"
  env                 = var.env
  instance_capacity   = var.frontend_instance_capacity
  instance_type       = var.frontend_instance_type
  project_name        = var.project_name
  sg_cidr_blocks      = var.web_subnets_cidr #this needs to be checked
  vpc_id              = module.vpc.vpc_id
  vpc_zone_identifier = module.vpc.web_subnets_ids
}

#public load balancer
module "public-alb" {
  source = "./module/alb"


  env              = var.env
  project_name     = var.project_name
  acm_arn          = var.acm_arn

  alb_name         = "public"
  internal         = false
  sg_cidr_blocks   = ["0.0.0.0/0"]

  subnets          = module.vpc.public_subnets_ids
  vpc_id           = module.vpc.vpc_id
  target_group_arn = module.frontend.target_group_arn
}

#private_load_balancer
module "private-alb" {
  source = "./module/alb"

  env              = var.env
  project_name     = var.project_name
  acm_arn          = var.acm_arn

  alb_name         = "private"
  internal         = true
  sg_cidr_blocks   = var.web_subnets_cidr

  subnets          = module.vpc.app_subnets_ids
  vpc_id           = module.vpc.vpc_id
  target_group_arn = module.backend.target_group_arn
}