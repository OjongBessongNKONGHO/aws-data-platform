# ─────────────────────────────────────────────────────────────
# Storage Module — S3 Data Lake
# ojong-data-platform
# ─────────────────────────────────────────────────────────────

# S3 Data Lake Bucket
# Cost estimate: $0.023/GB/month (Standard storage, us-east-1)
# PUT/GET requests: $0.005 per 1,000 PUT, $0.0004 per 1,000 GET
# Free tier: 5GB storage, 20,000 GET, 2,000 PUT requests for 12 months
resource "aws_s3_bucket" "data_lake" {
  bucket = var.bucket_name

  tags = {
    Name        = var.bucket_name
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Purpose     = "Data Lake"
  }
}

# Block all public access — data lake is private
resource "aws_s3_bucket_public_access_block" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable versioning — keeps history of every data file
resource "aws_s3_bucket_versioning" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

# Server-side encryption — all data encrypted at rest
resource "aws_s3_bucket_server_side_encryption_configuration" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Lifecycle policy — automatically move data to cheaper storage tiers
# Standard-IA: $0.0125/GB/month (saves ~46% vs Standard after 30 days)
# Glacier: $0.004/GB/month (saves ~83% vs Standard after 60 days)
resource "aws_s3_bucket_lifecycle_configuration" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id

  # Raw data — move to Infrequent Access after 30 days
  rule {
    id     = "raw-data-lifecycle"
    status = "Enabled"

    filter {
      prefix = "raw/"
    }

    transition {
      days          = var.raw_data_expiry_days
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 60
      storage_class = "GLACIER"
    }
  }

  # Processed data — archive after 90 days
  rule {
    id     = "processed-data-lifecycle"
    status = "Enabled"

    filter {
      prefix = "processed/"
    }

    transition {
      days          = var.processed_data_expiry_days
      storage_class = "STANDARD_IA"
    }
  }
}

# S3 folder structure — creates logical partitions for the data lake
resource "aws_s3_object" "raw_folder" {
  bucket  = aws_s3_bucket.data_lake.id
  key     = "raw/"
  content = ""
}

resource "aws_s3_object" "processed_folder" {
  bucket  = aws_s3_bucket.data_lake.id
  key     = "processed/"
  content = ""
}

resource "aws_s3_object" "archive_folder" {
  bucket  = aws_s3_bucket.data_lake.id
  key     = "archive/"
  content = ""
}

resource "aws_s3_object" "logs_folder" {
  bucket  = aws_s3_bucket.data_lake.id
  key     = "logs/"
  content = ""
}