# ─────────────────────────────────────────────────────────────
# Root Variables — ojong-data-platform
# ─────────────────────────────────────────────────────────────

variable "project_name" {
  description = "Name of the project — used to name and tag all AWS resources"
  type        = string
  default     = "ojong-data-platform"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region to deploy all resources — Paris"
  type        = string
  default     = "eu-west-3"
}

variable "bucket_name" {
  description = "Globally unique name for the S3 data lake bucket"
  type        = string
}

variable "key_pair_name" {
  description = "Name of the EC2 key pair for SSH access"
  type        = string
}

variable "db_password" {
  description = "Master password for the RDS PostgreSQL instance"
  type        = string
  sensitive   = true
}

variable "alarm_email" {
  description = "Email address to receive CloudWatch alarm notifications"
  type        = string
}

variable "ec2_instance_type" {
  description = "EC2 instance type — t2.micro is free tier eligible"
  type        = string
  default     = "t3.micro"
}

variable "db_instance_class" {
  description = "RDS instance class — db.t3.micro is free tier eligible"
  type        = string
  default     = "db.t3.micro"
}