
# ECR repository ( secure garage pour l'image docker de l'app)


resource "aws_ecr_repository" "aegis_repo" {
    name = "aegis-ai-agent"
    image_tag_mutability = "MUTABLE" 
    force_delete = true 


# activating scan vulnerabilites a chaque push (shift left security)
    image_scanning_configuration {
        scan_on_push = true
    }

    tags = {
            Project     = "AEGIS-AI"
    Environment = "Dev"
    }
}


#LIFECYVLE POLICY
# en prod we only keep 5 latest images

resource "aws_ecr_lifecycle_policy" "aegis_lifecyvle" {
    repository = aws_ecr_repository.aegis_repo.name

    policy = jsonencode({
        rules = [
            {
             rulePriority = 1
             description  = "Garder uniquement les 5 dernières images"
             selection = {
                tagStatus   = "any"
                countType   = "imageCountMoreThan"
                countNumber = 5  
            }

            action = {
                type = "expire" # Dit à AWS de supprimer les vieilles images
             }
            }
        ]
    })




}