# Changelog

All notable changes to this project are documented here.

## [1.0.0] - 2026-05-22

### Added
- Terraform 1.15.3 with AWS provider 5.100.0 targeting eu-west-3 Paris
- 41 AWS resources across 5 modules: networking, compute, storage, database, monitoring
- VPC with public and private subnets, Internet Gateway, route tables
- EC2 t3.micro with Docker and Python pre-installed via user_data
- RDS PostgreSQL 15.10 in private subnet with no internet exposure
- S3 data lake with AES256 encryption, versioning and lifecycle policies
- CloudWatch dashboard with 4 metric alarms and SNS email alerts
- IAM role with least-privilege access for EC2
- environments/dev and environments/prod directory structure
- CONTRIBUTING.md
- GitHub Actions CI with terraform fmt and validate on every push
- Mermaid architecture diagram in README
- Live AWS console screenshots in README
- terraform destroy completed with zero charges

## [1.0.1] - 2026-06-01

### Improved
- Added project roadmap: next steps include EKS cluster module and Glue ETL integration
