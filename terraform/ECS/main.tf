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
    "cpu": 0,
    "portMappings": [
        {
            "name": "nodejs-8080",
            "containerPort": 8080,
            "hostPort": 8080,
            "protocol": "tcp",
            "appProtocol": "http"
        }
    ],
    "essential": true,
    "environment": [],
    "environmentFiles": [],
    "mountPoints": [],
    "volumesFrom": [],
    "ulimits": [],
    "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
            "awslogs-create-group": "true",
            "awslogs-group": "/ecs/node",
            "awslogs-region": "ap-southeast-1",
            "awslogs-stream-prefix": "ecs"
        },
        "secretOptions": []
    }
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
  desired_count   = 4
  launch_type = "FARGATE"
  platform_version = "LATEST"
  deployment_circuit_breaker{
    enable = true
    rollback = true
  }
  # lifecycle {
  #   ignore_changes = [desired_count]
  # }
  
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
  depends_on = [ aws_ecs_task_definition.definition , aws_ecs_cluster.cluster ]
}