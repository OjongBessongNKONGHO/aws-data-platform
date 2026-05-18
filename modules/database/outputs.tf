output "db_instance_id" {
  description = "ID of the RDS instance"
  value       = aws_db_instance.postgres.id
}

output "db_endpoint" {
  description = "Connection endpoint for the RDS instance"
  value       = aws_db_instance.postgres.endpoint
}

output "db_port" {
  description = "Port the RDS instance listens on"
  value       = aws_db_instance.postgres.port
}

output "db_name" {
  description = "Name of the database"
  value       = aws_db_instance.postgres.db_name
}

output "db_username" {
  description = "Master username for the database"
  value       = aws_db_instance.postgres.username
  sensitive   = true
}

output "db_arn" {
  description = "ARN of the RDS instance"
  value       = aws_db_instance.postgres.arn
}