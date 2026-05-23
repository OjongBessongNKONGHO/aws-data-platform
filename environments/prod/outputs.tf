# ─────────────────────────────────────────────────────────────
# Production Environment Outputs — ojong-data-platform
# ─────────────────────────────────────────────────────────────

output "vpc_id" {
  description = "ID of the production VPC"
  value       = module.networking.vpc_id
}

output "ec2_public_ip" {
  description = "Public IP of the production EC2 instance"
  value       = module.compute.instance_public_ip
}

output "ec2_ssh_command" {
  description = "SSH command to connect to production EC2"
  value       = "ssh -i ~/.ssh/${var.key_pair_name}.pem ec2-user@${module.compute.instance_public_ip}"
}

output "rds_endpoint" {
  description = "Production RDS PostgreSQL endpoint"
  value       = module.database.db_endpoint
}

output "s3_bucket_name" {
  description = "Production S3 data lake bucket name"
  value       = module.storage.bucket_id
}

output "cloudwatch_dashboard_url" {
  description = "Production CloudWatch dashboard URL"
  value       = module.monitoring.dashboard_url
}