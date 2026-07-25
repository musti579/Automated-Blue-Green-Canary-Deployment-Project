resource "aws_vpc_endpoint" "s3_endpoint" {
  vpc_id       = var.vpc_id
  service_name = "com.amazonaws.eu-north-1.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids = [var.private_rt]

  tags = {
    Name = "s3_endpoint"
  }
}

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.eu-north-1.ecr.api"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = var.private_subnet_ids

  security_group_ids = [
    aws_security_group.endpoint_sg.id,
  ]
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.eu-north-1.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = var.private_subnet_ids

  security_group_ids = [
    aws_security_group.endpoint_sg.id,
  ]
}

resource "aws_vpc_endpoint" "sqs_endpoint" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.eu-north-1.sqs"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = var.private_subnet_ids

  security_group_ids = [
    aws_security_group.endpoint_sg.id,
  ]
}

resource "aws_vpc_endpoint" "cloudwatch_endpoint" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.eu-north-1.logs"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = var.private_subnet_ids

  security_group_ids = [
    aws_security_group.endpoint_sg.id,
  ]
}

resource "aws_vpc_endpoint" "secret_manager_endpoint" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.eu-north-1.secretsmanager"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = var.private_subnet_ids

  security_group_ids = [
    aws_security_group.endpoint_sg.id,
  ]
}

resource "aws_security_group" "endpoint_sg" {
  name   = "endpoint_sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}