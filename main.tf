# 1. Create ECR Repository
resource "aws_ecr_repository" "web_app" {
  name                 = "web-app"
  image_tag_mutability = "MUTABLE"

  lifecycle {
    prevent_destroy = false
  }
}


# 2. Create ECS Cluster
resource "aws_ecs_cluster" "my_cluster" {
  name = "web-app"
}

# 3. Create a Security Group
resource "aws_security_group" "ecs_sg" {
  name_prefix = "ecs-sg-WebApp"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# 4. Create a Load Balancer
resource "aws_lb" "ecs_lb" {
  name               = "ecs-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ecs_sg.id]
  subnets           = [aws_subnet.public_subnet.id, aws_subnet.private_subnet.id]
}

resource "aws_lb_target_group" "ecs_tg" {
  name     = "ecs-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  target_type = "ip"

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.ecs_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Service Unavailable"
      status_code  = "503"
    }
  }
}

resource "aws_lb_listener_rule" "ecs_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_tg.arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}

# IAM Role for ECS Execution
resource "aws_iam_role" "ecs_execution_role" {
  name               = "ecsExecutionRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_attach" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# 5. Create an ECS Task Definition
resource "aws_ecs_task_definition" "web_task" {
  family                   = "web-app-task"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  container_definitions    = jsonencode([
    {
      name      = "web-app"
      image     = "${aws_ecr_repository.web_app.repository_url}:latest"
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [{
        containerPort = 80
        hostPort      = 80
      }]
    }
  ])
}

# 6. Create an ECS Service
resource "aws_ecs_service" "web_service" {
  name            = "web-app-service"
  cluster         = aws_ecs_cluster.my_cluster.id
  task_definition = aws_ecs_task_definition.web_task.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [aws_subnet.public_subnet.id, aws_subnet.private_subnet.id]
    security_groups = [aws_security_group.ecs_sg.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_tg.arn
    container_name   = "web-app"
    container_port   = 80
  }
}