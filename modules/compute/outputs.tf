output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.pipeline.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_eip.pipeline.public_ip
}

output "instance_private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.pipeline.private_ip
}

output "instance_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_eip.pipeline.public_dns
}

output "iam_role_arn" {
  description = "ARN of the EC2 IAM role"
  value       = aws_iam_role.ec2_role.arn
}

output "ami_id" {
  description = "AMI ID used for the EC2 instance"
  value       = data.aws_ami.amazon_linux_2.id
}