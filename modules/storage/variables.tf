variable "project_name" {
  description = "Name of the project — used to tag all resources"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
}

variable "bucket_name" {
  description = "Name of the S3 data lake bucket — must be globally unique"
  type        = string
}

variable "enable_versioning" {
  description = "Enable versioning on the S3 bucket"
  type        = bool
  default     = true
}

variable "raw_data_expiry_days" {
  description = "Number of days before raw data is moved to cheaper storage"
  type        = number
  default     = 30
}

variable "processed_data_expiry_days" {
  description = "Number of days before processed data is archived"
  type        = number
  default     = 90
}