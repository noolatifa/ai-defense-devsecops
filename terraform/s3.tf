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



resource "aws_kms_key" "security_logs_key" {
  description             = "Key for AEGIS security logs bucket"  # a label, so you recognise it in the AWS console
  enable_key_rotation     = true   # AWS replaces the key material every year automatically
  deletion_window_in_days = 7      # if you delete the key, AWS waits 7 days first (deleting it makes the data unreadable forever)
}




# SECUTIYY !! AES ENCRYPTION for the content at rest
resource "aws_s3_bucket_server_side_encryption_configuration" "security_logs_encryption" {
  bucket = aws_s3_bucket.security_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"                                # encrypt with KMS instead of the AWS-owned AES key
      kms_master_key_id = aws_kms_key.security_logs_key.arn        # use the key from step 1    
      }
  }
}