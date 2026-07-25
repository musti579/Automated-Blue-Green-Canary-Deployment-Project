resource "random_password" "db" {
  length  = 32
  special = false
}

# using private subnets so the db is never directly reachable from the internet
resource "aws_db_subnet_group" "rds_subnet" {
  name       = "rds-subnet-group"
  subnet_ids = var.private_subnet_ids
  tags = {
    Name = "rds-subnet-group"
  }
}

# created rds database port exposed by default
resource "aws_db_instance" "rds_postgres" {
  allocated_storage      = var.db_allocated_storage
  db_name                = var.db_name
  engine                 = "postgres"
  engine_version         = var.db_engine_version
  instance_class         = var.db_instance_class
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet.name
  vpc_security_group_ids  = [aws_security_group.rds_sg.id]
  username               = var.db_username
  password               = random_password.db.result
  publicly_accessible    = false
  skip_final_snapshot    = true

  tags = {
    Name = "ecs2-postgres"
  }
}


resource "aws_secretsmanager_secret" "database_url" {
  name = "ecs2/database-url"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "database_url" {
  secret_id     = aws_secretsmanager_secret.database_url.id
  secret_string = "postgresql://${var.db_username}:${random_password.db.result}@${aws_db_instance.rds_postgres.address}:5432/${var.db_name}"
}

resource "aws_security_group" "rds_sg" {
  name   = "rds_sg"
  vpc_id = var.vpc_id

  ingress {
    from_port = 5432
    to_port = 5432
    protocol = "tcp" 
    cidr_blocks = [var.vpc_cidr]

  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]

  }
}