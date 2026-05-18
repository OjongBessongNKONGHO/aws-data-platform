# ─────────────────────────────────────────────────────────────
# Root Module — ojong-data-platform
# Provisions a complete data engineering infrastructure on AWS
# Author: Ojong Bessong NKONGHO
# ─────────────────────────────────────────────────────────────

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Owner       = "Ojong Bessong NKONGHO"
      Repository  = "github.com/OjongBessongNKONGHO/aws-data-platform"
    }
  }
}

# ── Networking ────────────────────────────────────────────────
module "networking" {
  source = "./modules/networking"

  project_name = var.project_name
  environment  = var.environment
}

# ── Storage ───────────────────────────────────────────────────
module "storage" {
  source = "./modules/storage"

  project_name = var.project_name
  environment  = var.environment
  bucket_name  = var.bucket_name
}

# ── Compute ───────────────────────────────────────────────────
module "compute" {
  source = "./modules/compute"

  project_name      = var.project_name
  environment       = var.environment
  subnet_id         = module.networking.public_subnet_ids[0]
  security_group_id = module.networking.ec2_security_group_id
  key_pair_name     = var.key_pair_name
  s3_bucket_arn     = module.storage.bucket_arn
  instance_type     = var.ec2_instance_type
}

# ── Database ──────────────────────────────────────────────────
module "database" {
  source = "./modules/database"

  project_name      = var.project_name
  environment       = var.environment
  subnet_ids        = module.networking.private_subnet_ids
  security_group_id = module.networking.rds_security_group_id
  db_password       = var.db_password
  db_instance_class = var.db_instance_class
}

# ── Monitoring ────────────────────────────────────────────────
module "monitoring" {
  source = "./modules/monitoring"

  project_name    = var.project_name
  environment     = var.environment
  ec2_instance_id = module.compute.instance_id
  db_instance_id  = module.database.db_instance_id
  s3_bucket_name  = module.storage.bucket_id
  alarm_email     = var.alarm_email
}