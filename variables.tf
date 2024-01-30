variable "env" {}
variable "project_name" {}
variable "kms_key_id" {}

variable "vpc_cidr" {}
variable "public_subnets_cidr" {}
variable "web_subnets_cidr" {}
variable "app_subnets_cidr" {}
variable "db_subnets_cidr" {}
variable "az" {}
variable "rds_allocated_storage" {}
variable "rds_db_name" {}
variable "rds_engine" {}
variable "rds_engine_version" {}
variable "rds-instance_class" {}
variable "rds_family" {}