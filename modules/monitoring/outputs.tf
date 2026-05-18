output "sns_topic_arn" {
  description = "ARN of the SNS alerts topic"
  value       = aws_sns_topic.alerts.arn
}

output "dashboard_url" {
  description = "URL of the CloudWatch dashboard"
  value       = "https://eu-west-3.console.aws.amazon.com/cloudwatch/home?region=eu-west-3#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
}

output "pipeline_log_group" {
  description = "Name of the pipeline CloudWatch log group"
  value       = aws_cloudwatch_log_group.pipeline_logs.name
}

output "ec2_log_group" {
  description = "Name of the EC2 CloudWatch log group"
  value       = aws_cloudwatch_log_group.ec2_logs.name
}