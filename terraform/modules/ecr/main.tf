resource "aws_ecr_repository" "api" {
  name                 = "ecs2-api"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "ecs2-api"
  }
}

resource "aws_ecr_repository" "worker" {
  name                 = "ecs2-worker"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "ecs2-worker"
  }
}

resource "aws_ecr_repository" "dashboard" {
  name                 = "ecs2-dashboard"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "ecs2-dashboard"
  }
}