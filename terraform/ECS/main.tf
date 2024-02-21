resource "aws_ecs_task_definition" "definition" {
  family                   = var.family_name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.cpu
  memory                   = var.memory
  container_definitions    = <<TASK_DEFINITION
[
  {
    "name": "${var.container_name}",
    "image": "${var.image}",
    "cpu": 1024,
    "memory": 2048,
    "essential": true,
    "portMappings": [
      {
        "containerPort": 8080,
        "hostPort": 8080
      }
    ]
  }
]
TASK_DEFINITION

  runtime_platform {
    operating_system_family = "${var.os}"
    cpu_architecture        = "${var.osarchitecture}"
  }
  task_role_arn = var.task_role_arn
  execution_role_arn = var.task_role_arn
}

resource "aws_ecs_cluster" "cluster" {
  name = var.ecs_cluster_name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}



resource "aws_ecs_service" "node_service" {
  name            = "terraform_nodejs_service"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.definition.arn
  desired_count   = 2
  lifecycle {
    ignore_changes = [desired_count]
  }
  
  network_configuration {
    subnets = [for subnet in var.subnetid : subnet]
    assign_public_ip = false
    security_groups = [var.ecs_sg_id]
  }

  load_balancer {
    target_group_arn = var.tgb_ecs_arn
    container_name   = var.container_name
    container_port   = var.container_port
  }
}