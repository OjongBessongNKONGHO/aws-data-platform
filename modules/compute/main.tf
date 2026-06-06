# ─────────────────────────────────────────────────────────────
# Compute Module — EC2 Instance + IAM Role
# ojong-data-platform
# ─────────────────────────────────────────────────────────────

# Get the latest Amazon Linux 2 AMI for eu-west-3
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# IAM Role — allows EC2 to access S3 and CloudWatch
resource "aws_iam_role" "ec2_role" {
  name = "${var.project_name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-ec2-role"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# IAM Policy — S3 read/write access for the data pipeline
resource "aws_iam_role_policy" "ec2_s3_policy" {
  name = "${var.project_name}-ec2-s3-policy"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          var.s3_bucket_arn,
          "${var.s3_bucket_arn}/*"
        ]
      }
    ]
  })
}

# IAM Policy — CloudWatch logs and metrics
resource "aws_iam_role_policy" "ec2_cloudwatch_policy" {
  name = "${var.project_name}-ec2-cloudwatch-policy"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "cloudwatch:GetMetricData",
          "cloudwatch:ListMetrics",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM Instance Profile — attaches the role to the EC2 instance
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

# EC2 Instance — runs the data pipeline
# Cost estimate: t3.micro = $0.0104/hour = ~$7.50/month (us-east-1)
# Free tier eligible: 750 hours/month for 12 months
resource "aws_instance" "pipeline" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  key_name               = var.key_pair_name

  # User data script — runs on first boot to set up the pipeline
  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -e

    # Update system
    yum update -y

    # Install Docker
    yum install -y docker
    systemctl start docker
    systemctl enable docker
    usermod -aG docker ec2-user

    # Install Docker Compose
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose

    # Install Python 3 and pip
    yum install -y python3 python3-pip git

    # Install AWS CLI v2
    pip3 install awscli

    # Install CloudWatch agent
    yum install -y amazon-cloudwatch-agent

    # Create pipeline directory
    mkdir -p /opt/ojong-data-platform
    chown ec2-user:ec2-user /opt/ojong-data-platform

    # Log setup completion
    echo "ojong-data-platform EC2 setup complete" >> /var/log/pipeline-setup.log
    echo "Instance: $(hostname)" >> /var/log/pipeline-setup.log
    echo "Date: $(date)" >> /var/log/pipeline-setup.log
  EOF
  )

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 20
    delete_on_termination = true

    tags = {
      Name        = "${var.project_name}-root-volume"
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }

  tags = {
    Name        = "${var.project_name}-pipeline-ec2"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Role        = "DataPipeline"
  }
}

# Elastic IP — gives the EC2 instance a fixed public IP address
# Cost estimate: $0.005/hour when associated with running instance = ~$3.60/month
# Free when associated with a running instance in free tier
resource "aws_eip" "pipeline" {
  instance = aws_instance.pipeline.id
  domain   = "vpc"

  tags = {
    Name        = "${var.project_name}-eip"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}