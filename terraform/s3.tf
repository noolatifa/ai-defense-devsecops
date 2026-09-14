# SECURE S3 bucket for security logs
#1- creation du bucket to store security logs
#2-block every public access
#3- content encryption at rest with aes


#bucket creation  (espace de stockage)
resource "aws_s3_bucket" "security_logs" {
    bucket = "aegis-ai-security-logs-local"
    force_destroy = true

    tags = {
        Project = "AEGIS-AI"
        Environment = "Dev"
        Purpose = "SecurityAuditLogs"
    }
}



# SECUTIYY !! Bloquer every public access

resource "aws_s3_bucket_public_access_block" "security_logs_block" {
    bucket = aws_s3_bucket.security_logs.id
    block_public_acls = true
    block_public_policy = true
    ignore_public_acls = true
    restrict_public_buckets = true
}


# SECUTIYY !! AES ENCRYPTION for the content at rest
resource "aws_s3_bucket_server_side_encryption_configuration" "security_logs_encryption" {
  bucket = aws_s3_bucket.security_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}