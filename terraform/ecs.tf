
#CLOUD WATCH LOG GROUP


resource "aws_cloudwatch_log_group" "aegis_logs" {
  name              = "/aegis-ai"
  retention_in_days = 7 #on efface les logs after 7 days

  tags = {
    Project = "AEGIS-AI"
  }
}

#ECS CLUSTER
resource "aws_ecs_cluster" "aegis_cluster" {
  name = "aegis-ai-cluster"

  tags = {
    Project = "AEGIS-AI"
  }
}


# TASK DEFINITION
resource "aws_ecs_task_definition" "aegis_task" {
  family                   = "aegis-ai-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 512
  memory                   = 1024


  # LIEN VERS IAM.TF :
  execution_role_arn = aws_iam_role.ecs_execution_role.arn
  task_role_arn      = aws_iam_role.my_ECS_badge.arn





  container_definitions = jsonencode([{
    name = "aegis-agent"

    image        = "WAITING_FOR_AWS_academy_ID.dkr.ecr.us-east-1.amazonaws.com/aegis-ai-agent:latest" #POOR LOFFFFFF ://
    essential    = true
    portMappings = [{ containerPort = 80, hostPort = 80, protocol = "tcp" }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.aegis_logs.name
        "awslogs-region"        = "us-east-1"
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])
  tags = { Project = "AEGIS-AI" }
}


#SERVICE
resource "aws_ecs_service" "aegis_service" {
  name            = "aegis-ai-service"
  cluster         = aws_ecs_cluster.aegis_cluster.id
  task_definition = aws_ecs_task_definition.aegis_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.private_subnet.id]
    security_groups  = [aws_security_group.aegis_ecs_sg.id]
    assign_public_ip = false
  }
  tags = { Project = "AEGIS-AI" }
}