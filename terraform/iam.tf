# IAM LEAST PRIVILEGE ROLE

# Qui peut utiliser ce role ? ONLY  AWS Lambda
data "aws_iam_policy_document" "agent_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}


# QUE PEUT FAIRE CE ROLE ? (Principe du moindre privilege)
data "aws_iam_policy_document" "agent_restrictive_policy" {
  
  # ALLOW: Lire les logs de securite (pour que l'agent puisse s'auto-auditer)
  statement {
    sid       = "AllowReadInternalLogs"
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:ListBucket"]
    resources = [
      aws_s3_bucket.security_logs.arn,
      "${aws_s3_bucket.security_logs.arn}/*"
    ]
  }


  # ALLOW: Ecrire dans CloudWatch for monitoring 
  statement {
    sid       = "AllowCloudWatchLogs"
    effect    = "Allow"
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["arn:aws:logs:*:*:*"]
  }



# DENY : interdiction de toute ecriture ou suppression de s3
  statement {
    sid       = "DenyExternalExfiltration"
    effect    = "Deny"
    actions   = ["s3:PutObject", "s3:DeleteObject", "s3:PutObjectAcl"]
    resources = ["*"]
  }
}


#  ASSEMBLAGE de role et de policy
resource "aws_iam_role" "aegis_agent_role" {
  name               = "aegis-agent-role"
  assume_role_policy = data.aws_iam_policy_document.agent_assume_role.json
}

resource "aws_iam_role_policy" "aegis_agent_policy" {
  name   = "aegis-agent-restrictive-policy"
  role   = aws_iam_role.aegis_agent_role.id
  policy = data.aws_iam_policy_document.agent_restrictive_policy.json
}