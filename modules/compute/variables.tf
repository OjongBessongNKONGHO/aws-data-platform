variable "project_name" {
  description = "Name of the project — used to tag all resources"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type — t2.micro is free tier eligible"
  type        = string
  default     = "t2.micro"
}

variable "subnet_id" {
  description = "ID of the public subnet to launch the EC2 instance in"
  type        = string
}

variable "security_group_id" {
  description = "ID of the security group for the EC2 instance"
  type        = string
}

variable "key_pair_name" {
  description = "Name of the EC2 key pair for SSH access"
  type        = string
}

variable "s3_bucket_arn" {
  description = "ARN of the S3 data lake bucket — grants EC2 access"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance — Amazon Linux 2 in eu-west-3"
  type        = string
  default     = "ami-0c55b159cbfafe1f0"
}