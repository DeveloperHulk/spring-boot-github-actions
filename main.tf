provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket         = "terraform-state-bucket87096"
    key            = "ecs/terraform.tfstate"  # Change "ecs" if needed
    region         = "us-east-1"              # Change to your S3 region
    encrypt        = true
  }
}

# Fetch Default VPC
data "aws_vpc" "default" {
  default = true
}

# Fetch Default Subnets
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Fetch Default Security Group
data "aws_security_group" "default" {
  id = "sg-08005a0fe126ac723"  # Replace with the actual security group ID
}

# Create Public ECR Repository
resource "aws_ecrpublic_repository" "spring_boot_repo" {
  repository_name = "rahul87096/spring-boot-demo"
}

# Create ECS Cluster
resource "aws_ecs_cluster" "spring_boot_cluster" {
  name = "my-ecs-cluster-v3"
}

# Create ECS Task Definition
resource "aws_ecs_task_definition" "spring_boot_task" {
  family                   = "spring-boot-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  execution_role_arn       = data.aws_iam_role.ecs_task_execution_role.arn
  cpu                      = "512"
  memory                   = "2048"

  container_definitions = jsonencode([
    {
      name      = "spring-boot-container"
      image     = "${aws_ecrpublic_repository.spring_boot_repo.repository_uri}:latest"
      cpu       = 512
      memory    = 2048
      essential = true
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
        }
      ]
    }
  ])
}

data "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"
}


# Create an ALB
resource "aws_lb" "spring_boot_alb" {
  name               = "spring-boot-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [data.aws_security_group.default.id]
  subnets            = data.aws_subnets.default.ids
}

# Create a Target Group
resource "aws_lb_target_group" "spring_boot_tg" {
  name        = "spring-boot-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default.id
  target_type = "ip"
}

# ALB Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.spring_boot_alb.arn
  port              = 8080
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.spring_boot_tg.arn
  }
}

# Create ECS Service
resource "aws_ecs_service" "spring_boot_service" {
  name            = "spring-boot-service"
  cluster         = aws_ecs_cluster.spring_boot_cluster.id
  task_definition = aws_ecs_task_definition.spring_boot_task.arn
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = data.aws_subnets.default.ids
    security_groups  = [data.aws_security_group.default.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.spring_boot_tg.arn
    container_name   = "spring-boot-container"
    container_port   = 8080
  }
}
