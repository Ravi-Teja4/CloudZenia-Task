
# VPC
resource "aws_vpc" "cloudzenia_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "cloudzenia-vpc" }
}

# Internet Gateway
resource "aws_internet_gateway" "cloudzenia_igw" {
  vpc_id = aws_vpc.cloudzenia_vpc.id
  tags   = { Name = "cloudzenia-igw" }
}

# Subnets
resource "aws_subnet" "cloudzenia_public_1" {
  vpc_id                  = aws_vpc.cloudzenia_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-2a"
  map_public_ip_on_launch = true
  tags                    = { Name = "cloudzenia-public-subnet-1" }
}

resource "aws_subnet" "cloudzenia_public_2" {
  vpc_id                  = aws_vpc.cloudzenia_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-2b"
  map_public_ip_on_launch = true
  tags                    = { Name = "cloudzenia-public-subnet-2" }
}

resource "aws_subnet" "cloudzenia_private_1" {
  vpc_id            = aws_vpc.cloudzenia_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-2a"
  tags              = { Name = "cloudzenia-private-subnet-1" }
}

resource "aws_subnet" "cloudzenia_private_2" {
  vpc_id            = aws_vpc.cloudzenia_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-2b"
  tags              = { Name = "cloudzenia-private-subnet-2" }
}

# NAT Gateway
resource "aws_eip" "cloudzenia_nat_eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "cloudzenia_nat" {
  allocation_id = aws_eip.cloudzenia_nat_eip.id
  subnet_id     = aws_subnet.cloudzenia_public_1.id
  depends_on    = [aws_internet_gateway.cloudzenia_igw]
  tags          = { Name = "cloudzenia-nat-gateway" }
}

# Route Tables
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.cloudzenia_vpc.id
  tags   = { Name = "cloudzenia-public-rt" }
}

resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.cloudzenia_igw.id
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.cloudzenia_vpc.id
  tags   = { Name = "cloudzenia-private-rt" }
}

resource "aws_route" "private_route" {
  route_table_id         = aws_route_table.private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.cloudzenia_nat.id
}

resource "aws_route_table_association" "public_assoc_1" {
  subnet_id      = aws_subnet.cloudzenia_public_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_assoc_2" {
  subnet_id      = aws_subnet.cloudzenia_public_2.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "private_assoc_1" {
  subnet_id      = aws_subnet.cloudzenia_private_1.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_assoc_2" {
  subnet_id      = aws_subnet.cloudzenia_private_2.id
  route_table_id = aws_route_table.private_rt.id
}

# Security Groups
resource "aws_security_group" "app_sg" {
  name        = "cloudzenia-app-sg"
  description = "Security group for application"
  vpc_id      = aws_vpc.cloudzenia_vpc.id

  tags = { Name = "cloudzenia-app-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "app_http" {
  security_group_id = aws_security_group.app_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "app_nodejs" {
  security_group_id = aws_security_group.app_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 3000
  to_port           = 3000
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "app_egress" {
  security_group_id = aws_security_group.app_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_security_group" "rds_sg" {
  name        = "cloudzenia-rds-sg"
  description = "Security group for RDS"
  vpc_id      = aws_vpc.cloudzenia_vpc.id

  tags = { Name = "cloudzenia-rds-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "rds_mysql" {
  security_group_id            = aws_security_group.rds_sg.id
  referenced_security_group_id = aws_security_group.app_sg.id
  from_port                    = 3306
  to_port                      = 3306
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "rds_egress" {
  security_group_id = aws_security_group.rds_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# RDS MySQL (WordPress)
resource "aws_db_subnet_group" "rds_subnet" {
  name       = "cloudzenia-rds-subnet-group"
  subnet_ids = [aws_subnet.cloudzenia_private_1.id, aws_subnet.cloudzenia_private_2.id]

  tags = { Name = "cloudzenia-rds-subnet-group" }
}

resource "aws_db_instance" "mysql" {
  identifier             = "cloudzenia-mysql"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  db_name                = "wordpress"
  username               = "RaviTeja"
  password               = "RaviTeja123"
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot    = true
  publicly_accessible    = false

  tags = { Name = "cloudzenia-mysql" }
}

# ECR Repositories
resource "aws_ecr_repository" "wordpress" {
  name = "cloudzenia-wordpress"

  tags = { Name = "cloudzenia-wordpress" }
}

resource "aws_ecr_repository" "nodejs" {
  name = "cloudzenia-nodejs"

  tags = { Name = "cloudzenia-nodejs" }
}

# ECS Cluster & IAM
resource "aws_ecs_cluster" "cluster" {
  name = "cloudzenia-cluster"

  tags = { Name = "cloudzenia-cluster" }
}

resource "aws_iam_role" "ecs_exec_role" {
  name = "ecsTaskExecutionRole-cloudzenia"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = { Name = "ecs-task-execution-role" }
}

resource "aws_iam_role_policy_attachment" "ecs_policy" {
  role       = aws_iam_role.ecs_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Inline policy for CloudWatch Logs (doesn't count toward 10-policy limit)
resource "aws_iam_role_policy" "ecs_cloudwatch_logs" {
  name = "ecs-cloudwatch-logs-inline-policy"
  role = aws_iam_role.ecs_exec_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [
          "arn:aws:logs:us-east-2:913723800201:log-group:/ecs/wordpress:*",
          "arn:aws:logs:us-east-2:913723800201:log-group:/ecs/nodejs:*"
        ]
      }
    ]
  })
}

# ALB
resource "aws_lb" "alb" {
  name               = "cloudzenia-alb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.app_sg.id]
  subnets            = [aws_subnet.cloudzenia_public_1.id, aws_subnet.cloudzenia_public_2.id]

  tags = { Name = "cloudzenia-alb" }
}

resource "aws_lb_target_group" "tg_wordpress" {
  name        = "TG-wordpress"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.cloudzenia_vpc.id
  target_type = "ip"
  
  deregistration_delay = 30

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/"
    matcher             = "200-499"  # WordPress may return redirects
    port                = "traffic-port"
  }

  tags = { Name = "TG-wordpress" }
}

resource "aws_lb_target_group" "tg_nodejs" {
  name        = "TG-nodejs"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.cloudzenia_vpc.id
  target_type = "ip"
  
  deregistration_delay = 30

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 10  # Increased to allow more failures
    timeout             = 10
    interval            = 30
    path                = "/"  # Changed from /api to /
    matcher             = "200-499"
    port                = "traffic-port"
  }

  tags = { Name = "TG-nodejs" }
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_wordpress.arn
  }

  tags = { Name = "cloudzenia-listener" }
}

resource "aws_lb_listener_rule" "nodejs_rule" {
  listener_arn = aws_lb_listener.listener.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_nodejs.arn
  }

  condition {
    path_pattern {
      values = ["/api*"]
    }
  }

  tags = { Name = "nodejs-rule" }
}

# ECS Task Definitions
resource "aws_ecs_task_definition" "wordpress" {
  family                   = "wordpress"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_exec_role.arn

  container_definitions = jsonencode([{
    name  = "wordpress"
    image = "${aws_ecr_repository.wordpress.repository_url}:latest"
    portMappings = [{
      containerPort = 80
      protocol      = "tcp"
    }]
    environment = [
      { name = "WORDPRESS_DB_HOST", value = aws_db_instance.mysql.address },
      { name = "WORDPRESS_DB_USER", value = "wpuser" },
      { name = "WORDPRESS_DB_PASSWORD", value = "wppassword123" },
      { name = "WORDPRESS_DB_NAME", value = "wordpress" }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/wordpress"
        "awslogs-region"        = "us-east-2"
        "awslogs-stream-prefix" = "ecs"
        "awslogs-create-group"  = "true"
      }
    }
  }])

  tags = { Name = "wordpress-task" }
}

resource "aws_ecs_task_definition" "nodejs" {
  family                   = "nodejs"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_exec_role.arn

  container_definitions = jsonencode([{
    name  = "nodejs"
    image = "${aws_ecr_repository.nodejs.repository_url}:latest"
    portMappings = [{
      containerPort = 3000
      protocol      = "tcp"
    }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/nodejs"
        "awslogs-region"        = "us-east-2"
        "awslogs-stream-prefix" = "ecs"
        "awslogs-create-group"  = "true"
      }
    }
  }])

  tags = { Name = "nodejs-task" }
}

# ECS Services
resource "aws_ecs_service" "wordpress" {
  name            = "wordpress-service"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.wordpress.arn
  desired_count   = var.wordpress_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [aws_subnet.cloudzenia_private_1.id, aws_subnet.cloudzenia_private_2.id]
    security_groups = [aws_security_group.app_sg.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.tg_wordpress.arn
    container_name   = "wordpress"
    container_port   = 80
  }

  depends_on = [aws_lb_listener.listener]

  tags = { Name = "wordpress-service" }
}

resource "aws_ecs_service" "nodejs" {
  name            = "nodejs-service"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.nodejs.arn
  desired_count   = var.nodejs_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [aws_subnet.cloudzenia_private_1.id, aws_subnet.cloudzenia_private_2.id]
    security_groups = [aws_security_group.app_sg.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.tg_nodejs.arn
    container_name   = "nodejs"
    container_port   = 3000
  }

  depends_on = [aws_lb_listener.listener]

  tags = { Name = "nodejs-service" }
}


# Variables
variable "wordpress_desired_count" {
  description = "Number of WordPress tasks to run"
  type        = number
  default     = 1  # Changed from 0 to 1
}

variable "nodejs_desired_count" {
  description = "Number of NodeJS tasks to run"
  type        = number
  default     = 1  # Changed from 0 to 1
}

# Outputs
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.alb.dns_name
}

output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.mysql.endpoint
}

output "ecr_wordpress_url" {
  description = "ECR repository URL for WordPress"
  value       = aws_ecr_repository.wordpress.repository_url
}

output "ecr_nodejs_url" {
  description = "ECR repository URL for NodeJS"
  value       = aws_ecr_repository.nodejs.repository_url
}
