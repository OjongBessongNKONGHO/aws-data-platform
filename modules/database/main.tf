# ─────────────────────────────────────────────────────────────
# Database Module — RDS PostgreSQL
# ojong-data-platform
# ─────────────────────────────────────────────────────────────

# RDS Subnet Group — tells RDS which subnets it can use
# Uses private subnets — database is never directly accessible from internet
resource "aws_db_subnet_group" "main" {
  name        = "${var.project_name}-db-subnet-group"
  subnet_ids  = var.subnet_ids
  description = "Subnet group for ${var.project_name} RDS instance"

  tags = {
    Name        = "${var.project_name}-db-subnet-group"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# RDS PostgreSQL Instance
# Cost estimate: db.t3.micro = $0.017/hour = ~$12.24/month (us-east-1)
# Storage: gp2 $0.115/GB/month — 20GB = ~$2.30/month
# Total estimated cost: ~$14.54/month
# Free tier: 750 hours db.t3.micro + 20GB storage for 12 months
resource "aws_db_instance" "postgres" {
  identifier        = "${var.project_name}-postgres"
  engine            = "postgres"
  engine_version    = "15.13"
  instance_class    = var.db_instance_class
  allocated_storage = var.allocated_storage
  storage_type      = "gp2"
  storage_encrypted = true

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.security_group_id]

  # Backups
  backup_retention_period = 0
  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"

  # Production settings
  multi_az            = false
  publicly_accessible = false
  deletion_protection = false
  skip_final_snapshot = true

  # Performance Insights — free tier monitoring
  performance_insights_enabled = false

  # Enhanced monitoring
  monitoring_interval = 0

  tags = {
    Name        = "${var.project_name}-postgres"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Engine      = "PostgreSQL"
  }
}