resource "aws_security_group" "alb-sg" {
  name        = "alb-sg"
  description = "Application load balancer security group"
  vpc_id      = var.vpc_id

 # Allow all inbound traffic.
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}




resource "aws_lb" "alb" {
  name               = "ecs2-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb-sg.id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = false

  tags = {
    Name = "ecs2-alb"
  }
}


resource "aws_security_group" "ecs2_sg" {
  name        = "ecs2-sg"
  description = "ECS task security group - only allows traffic from the ALB"
  vpc_id      = var.vpc_id

  ingress {
    description     = "api from ALB"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb-sg.id]
  
  }

  ingress {
    description     = "dashboard from ALB"
    from_port       = 8081
    to_port         = 8081
    protocol        = "tcp"
    security_groups = [aws_security_group.alb-sg.id]
  
  }

  egress {
    description = "allow tasks to reach RDS, Redis and VPC endpoints"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ecs2-sg"
  }
}


  # Target Group forwarding traffic to Api blue & Green with health checks.
resource "aws_lb_target_group" "api_blue" {
  name        = "ecs2-api-blue"
  target_type = "ip"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = var.vpc_id

  health_check {
    path                = "/healthz"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

resource "aws_lb_target_group" "api_green" {
  name        = "ecs2-api-green"
  target_type = "ip"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = var.vpc_id

  health_check {
    path                = "/healthz"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}


  # Target Group forwarding traffic to Dashboard blue & Green with health checks.
resource "aws_lb_target_group" "dashboard_blue" {
  name        = "ecs2-dashboard-blue"
  target_type = "ip"
  port        = 8081
  protocol    = "HTTP"
  vpc_id      = var.vpc_id

  health_check {
    path                = "/healthz"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

resource "aws_lb_target_group" "dashboard_green" {
  name        = "ecs2-dashboard-green"
  target_type = "ip"
  port        = 8081
  protocol    = "HTTP"
  vpc_id      = var.vpc_id

  health_check {
    path                = "/healthz"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

# Redirects all HTTP traffic on port 80 to HTTPS, no longer forwards to any target group
resource "aws_lb_listener" "api_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}
# HTTPS listener on port 443, serves traffic using the validated ACM cert
resource "aws_lb_listener" "api_listener_https" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api_blue.arn
  }

  lifecycle {
    ignore_changes = [default_action]
  }
}


# listener rule given listens to any of the condition if meet then traffic is sent to dashboard blue
resource "aws_lb_listener_rule" "dashboard_listener" {
  listener_arn = aws_lb_listener.api_listener_https.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.dashboard_blue.arn
  }

   condition {
    path_pattern {
      values = ["/summary", "/url/*", "/recent", "/top"]
    }
  }
}

resource "aws_wafv2_web_acl" "alb" {
  name  = "ecs2-waf"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "common-rules"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "common-rules"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "ecs2-waf"
    sampled_requests_enabled   = true
  }

  tags = {
    Name = "ecs2-waf"
  }
}

resource "aws_wafv2_web_acl_association" "alb" {
  resource_arn = aws_lb.alb.arn
  web_acl_arn  = aws_wafv2_web_acl.alb.arn
}