# SECURE S3 bucket for security logs



#bucket creation  (espace de stockage)
ressource "aws_s3_bucket" "security_logs" {
    bucket = "aegis-ai-security-logs_local"

    tags = {
        Project = "AEGIS-AI"
        Envirronment = "Dev"
        Purpose = "SecurityAuditLogs"
    }
}



# SECUTIYY !! Bloquer every public access

ressource = "aws_s3_bucket_public_access_block" "security_logs_block" {
    bucket = aws_s3_bucket.security_logs.skip_requesting_account_id

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