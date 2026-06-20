variable "project_name" {
  description = "Name of the project — used to tag all resources"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
}

variable "ec2_instance_id" {
  description = "ID of the EC2 instance to monitor"
  type        = string
}

variable "db_instance_id" {
  description = "ID of the RDS instance to monitor"
  type        = string
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket to monitor"
  type        = string
}

variable "alarm_email" {
  description = "Email address to receive CloudWatch alarm notifications"
  type        = string
}

variable "ec2_cpu_threshold" {
  description = "CPU utilization percentage that triggers an alarm"
  type        = number
  default     = 80
}

variable "rds_cpu_threshold" {
  description = "RDS CPU utilization percentage that triggers an alarm"
  type        = number
  default     = 80
}

variable "rds_connections_threshold" {
  description = "Number of RDS connections that triggers an alarm"
  type        = number
  default     = 50
}
variable "s3_bucket_size_threshold_bytes" {
  description = "S3 bucket size in bytes that triggers an alarm — default is 5GB"
  type        = number
  default     = 5368709120
}