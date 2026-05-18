output "bucket_id" {
  description = "ID of the S3 data lake bucket"
  value       = aws_s3_bucket.data_lake.id
}

output "bucket_arn" {
  description = "ARN of the S3 data lake bucket"
  value       = aws_s3_bucket.data_lake.arn
}

output "bucket_domain_name" {
  description = "Domain name of the S3 bucket"
  value       = aws_s3_bucket.data_lake.bucket_domain_name
}

output "bucket_regional_domain_name" {
  description = "Regional domain name of the S3 bucket"
  value       = aws_s3_bucket.data_lake.bucket_regional_domain_name
}