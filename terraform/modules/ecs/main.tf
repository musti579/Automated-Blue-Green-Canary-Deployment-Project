resource "aws_ecs_cluster" "ecs2_cluster" {
  name = "ecs2-cluster"

  setting {
    name  = "containerInsights"
    value = "disabled"
  }
}

resource "aws_cloudwatch_log_group" "cloudwatch_api_logs" {
  name              = "/ecs/ecs2-api"
  retention_in_days = 14

  tags = {
    Name = "ecs2-api-logs"
  }
}

resource "aws_cloudwatch_log_group" "cloudwatch_worker_logs" {
  name              = "/ecs/ecs2-worker"
  retention_in_days = 14

  tags = {
    Name = "ecs2-worker-logs"
  }
}

resource "aws_cloudwatch_log_group" "cloudwatch_dashboard_logs" {
  name              = "/ecs/ecs2-dashboard"
  retention_in_days = 14

  tags = {
    Name = "ecs2-dashboard-logs"
  }
}


resource "aws_iam_role" "execution" {
  name = "ecs2-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Name = "ecs2-task-execution-role"
  }
}

resource "aws_iam_role_policy" "execution_secrets" {
  name = "ecs2-execution-secrets"
  role = aws_iam_role.execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["secretsmanager:GetSecretValue"]
      Resource = var.db_secret_arn
    }]
  })
}


resource "aws_iam_role_policy_attachment" "execution_managed" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}


resource "aws_iam_role" "api_task" {
  name = "ecs2-api-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })

  tags = {
    Name = "ecs2-api-task-role"
  }
}


resource "aws_iam_role_policy" "api_sqs" {
  name = "ecs2-api-sqs"
  role = aws_iam_role.api_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "sqs:SendMessage"
      Resource = var.sqs_queue_arn
    }]
  })
}


resource "aws_iam_role" "worker_task" {
  name = "ecs2-worker-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })

  tags = {
    Name = "ecs2-worker-task-role"
  }
}

resource "aws_iam_role_policy" "worker_sqs" {
  name = "ecs2-worker-sqs"
  role = aws_iam_role.worker_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action = [
    "sqs:ReceiveMessage",           
    "sqs:DeleteMessage",
    "sqs:GetQueueAttributes"
    ]
      Resource = var.sqs_queue_arn
    }]
  })
}


resource "aws_ecs_task_definition" "api" {
  family                   = "ecs2-api"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.api_task.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  container_definitions = jsonencode([
    {
      name      = "api"
      image     = "${var.api_image_url}:v1"
      essential = true
      portMappings = [
        { containerPort = 8080, protocol = "tcp" }
      ]
      environment = [
        { name = "REDIS_URL",     value = var.redis_url },
        { name = "SQS_QUEUE_URL", value = var.sqs_queue_url },
        { name = "PORT",          value = "8080" }
      ]
            secrets = [
    { name = "DATABASE_URL", valueFrom = var.db_secret_arn }    
        ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/ecs2-api"
          "awslogs-region"        = "eu-north-1"
          "awslogs-stream-prefix" = "api"
        }
      }
    }
  ])
}

resource "aws_ecs_task_definition" "worker" {
  family                   = "ecs2-worker"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.worker_task.arn


  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
 container_definitions = jsonencode([
    {
      name      = "worker"
      image     = "${var.worker_image_url}:v1"
      essential = true
    
      environment = [
        { name = "SQS_QUEUE_URL", value = var.sqs_queue_url },
      ]
            secrets = [
    { name = "DATABASE_URL", valueFrom = var.db_secret_arn }    
        ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/ecs2-worker"
          "awslogs-region"        = "eu-north-1"
          "awslogs-stream-prefix" = "worker"
        }
      }
    }
  ])

}


resource "aws_ecs_task_definition" "dashboard" {
  family                   = "ecs2-dashboard"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.execution.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
 container_definitions = jsonencode([
    {
      name      = "dashboard"
      image     = "${var.dashboard_image_url}:v1"
      essential = true
      portMappings = [
        { containerPort = 8081, protocol = "tcp" }
      ]
       environment = [
        { name = "PORT",          value = "8081" }
      ]
            secrets = [
    { name = "DATABASE_URL", valueFrom = var.db_secret_arn }    
        ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/ecs2-dashboard"
          "awslogs-region"        = "eu-north-1"
          "awslogs-stream-prefix" = "dashboard"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "api" {
  name            = "ecs2-api"
  cluster         = aws_ecs_cluster.ecs2_cluster.id
  task_definition = aws_ecs_task_definition.api.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_sg_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.api_blue_tg_arn
    container_name   = "api"
    container_port   = 8080
  }

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  lifecycle {
    ignore_changes = [task_definition, load_balancer]
  }
}

resource "aws_ecs_service" "dashboard" {
  name            = "ecs2-dashboard"
  cluster         = aws_ecs_cluster.ecs2_cluster.id
  task_definition = aws_ecs_task_definition.dashboard.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_sg_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.dashboard_blue_tg_arn
    container_name   = "dashboard"
    container_port   = 8081
  }

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  lifecycle {
    ignore_changes = [task_definition, load_balancer]
  }
}

resource "aws_ecs_service" "worker" {
  name            = "ecs2-worker"
  cluster         = aws_ecs_cluster.ecs2_cluster.id
  task_definition = aws_ecs_task_definition.worker.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_sg_id]
    assign_public_ip = false
  }

  deployment_controller {
    type = "ECS"
  }
}