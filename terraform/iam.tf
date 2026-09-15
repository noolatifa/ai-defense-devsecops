#1 TRUST POLICY generation 
data "aws_iam_policy_document" "my_trust_policy" {
  statement {
    effect  = "Allow"
    # "sts:AssumeRole" est le terme technique AWS pour "porter un badge"
    actions = ["sts:AssumeRole"] 

    principals {
      type = "Service"
      # we say ONLY ECS peut porter ce badge 
      identifiers = ["ecs-tasks.amazonaws.com"]
    }

    }
}



# BADGE CREATION  (le role)
resource "aws_iam_role" "my_ECS_badge" {
  name = "aegis-ecs-task-role" 

  #we link the role (badge) to th ecreated trust policy 
  # SYNTAX --> data.nom_de_data.json
  assume_role_policy = data.aws_iam_policy_document.my_trust_policy.json

  }



  #2 Ce que le badge peut faire 
  data "aws_iam_policy_document" "my_permissions"{
    # Règle 1 : Autoriser la lecture S3
    statement {
      sid       = "AllowS3Read"       # nom de ref
      effect    = "Allow"           
      actions   = ["s3:GetObject", "s3:ListBucket"]    # L'action précise
      resources = [
        aws_s3_bucket.security_logs.arn, "${aws_s3_bucket.security_logs.arn}/*"
      ] # Sur quelles ressources ?
    }


    # Règle 2 : Autoriser l'écriture des logs dans CloudWatch
    statement {
      sid       = "AllowCloudWatch"
      effect    = "Allow"
      actions   = [
        "logs:CreateLogGroup", 
        "logs:CreateLogStream", 
        "logs:PutLogEvents"
      ]
      # On restreint l'écriture aux logs du projet AEGIS (bonne pratique)
      resources = ["arn:aws:logs:*:*:log-group:/aegis-ai/*"] 
    }




    # Règle 3: INTERDIRE formellement l'écriture, la suppression et le changement de droits
    statement {
      sid       = "DenyExternalExfiltration"
      effect    = "Deny"             
      actions   = [
        "s3:PutObject", 
        "s3:DeleteObject", 
        "s3:PutObjectAcl"
      ]    
      resources = ["*"]               
    }
  }

#3 attacher les permissions au badge avec le badge crée (my_ECS_badge) et my_permissions attached
resource "aws_iam_role_policy" "attacher_mes_permissions" {
  name   = "politique-de-securite-aegis"
  role = aws_iam_role.my_ECS_badge.id
  policy = data.aws_iam_policy_document.my_permissions.json
}


#NEW ROLE (EXECUTION ROLE) pour que ecs peut faire un pull img
resource "aws_iam_role" "ecs_execution_role" {
  name               = "aegis-ecs-execution-role"
  assume_role_policy = data.aws_iam_policy_document.my_trust_policy.json
}


resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}