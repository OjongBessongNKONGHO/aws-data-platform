# ─────────────────────────────────────────────────────────────
# Root Outputs — ojong-data-platform
# ─────────────────────────────────────────────────────────────

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "ec2_public_ip" {
  description = "Public IP address of the pipeline EC2 instance"
  value       = module.compute.instance_public_ip
}

output "ec2_public_dns" {
  description = "Public DNS of the EC2 instance — use this to SSH"
  value       = module.compute.instance_public_dns
}

output "ec2_ssh_command" {
  description = "SSH command to connect to the EC2 instance"
  value       = "ssh -i ~/.ssh/${var.key_pair_name}.pem ec2-user@${module.compute.instance_public_ip}"
}

output "rds_endpoint" {
  description = "RDS PostgreSQL connection endpoint"
  value       = module.database.db_endpoint
}

output "rds_port" {
  description = "RDS PostgreSQL port"
  value       = module.database.db_port
}

output "s3_bucket_name" {
  description = "Name of the S3 data lake bucket"
  value       = module.storage.bucket_id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 data lake bucket"
  value       = module.storage.bucket_arn
}

output "cloudwatch_dashboard_url" {
  description = "URL of the CloudWatch monitoring dashboard"
  value       = module.monitoring.dashboard_url
}

output "pipeline_log_group" {
  description = "CloudWatch log group for pipeline logs"
  value       = module.monitoring.pipeline_log_group
}

output "ami_used" {
  description = "AMI ID used for the EC2 instance"
  value       = module.compute.ami_id
}