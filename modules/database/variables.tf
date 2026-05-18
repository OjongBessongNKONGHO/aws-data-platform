variable "project_name" {
  description = "Name of the project — used to tag all resources"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
}

variable "subnet_ids" {
  description = "List of private subnet IDs for the RDS subnet group"
  type        = list(string)
}

variable "security_group_id" {
  description = "ID of the RDS security group"
  type        = string
}

variable "db_name" {
  description = "Name of the PostgreSQL database"
  type        = string
  default     = "weather_platform"
}

variable "db_username" {
  description = "Master username for the RDS instance"
  type        = string
  default     = "ojong_admin"
}

variable "db_password" {
  description = "Master password for the RDS instance — stored in tfvars, never committed"
  type        = string
  sensitive   = true
}

variable "db_instance_class" {
  description = "RDS instance class — db.t3.micro is free tier eligible"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Storage allocated to RDS in GB"
  type        = number
  default     = 20
}

variable "backup_retention_days" {
  description = "Number of days to retain automated backups"
  type        = number
  default     = 7
}