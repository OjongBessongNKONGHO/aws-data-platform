# ─────────────────────────────────────────────────────────────
# Production Environment Variables — ojong-data-platform
# ─────────────────────────────────────────────────────────────

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "ojong-data-platform"
}

variable "aws_region" {
  description = "AWS region — Paris"
  type        = string
  default     = "eu-west-3"
}

variable "bucket_name" {
  description = "Globally unique S3 bucket name for production data lake"
  type        = string
}

variable "key_pair_name" {
  description = "EC2 key pair name for SSH access"
  type        = string
}

variable "db_password" {
  description = "Master password for production RDS instance"
  type        = string
  sensitive   = true
}

variable "alarm_email" {
  description = "Email address for production CloudWatch alerts"
  type        = string
}

variable "ec2_instance_type" {
  description = "EC2 instance type — t3.small for production"
  type        = string
  default     = "t3.small"
}

variable "db_instance_class" {
  description = "RDS instance class — db.t3.small for production"
  type        = string
  default     = "db.t3.small"
}