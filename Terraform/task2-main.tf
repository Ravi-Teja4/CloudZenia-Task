
# vpc
resource "aws_vpc" "cloudzenia_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "cloudzenia-vpc"
  }
}

# internet gateway
resource "aws_internet_gateway" "cloudzenia_igw" {
  vpc_id = aws_vpc.cloudzenia_vpc.id

  tags = {
    Name = "cloudzenia-igw"
  }
}

# subnets
resource "aws_subnet" "cloudzenia_public_1" {
  vpc_id                  = aws_vpc.cloudzenia_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "cloudzenia-public-subnet-1"
  }
}

resource "aws_subnet" "cloudzenia_public_2" {
  vpc_id                  = aws_vpc.cloudzenia_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-2b"
  map_public_ip_on_launch = true

  tags = {
    Name = "cloudzenia-public-subnet-2"
  }
}

resource "aws_subnet" "cloudzenia_private_1" {
  vpc_id            = aws_vpc.cloudzenia_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-2a"

  tags = {
    Name = "cloudzenia-private-subnet-1"
  }
}

resource "aws_subnet" "cloudzenia_private_2" {
  vpc_id            = aws_vpc.cloudzenia_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-2b"

  tags = {
    Name = "cloudzenia-private-subnet-2"
  }
}

# nat gateway
resource "aws_eip" "cloudzenia_nat_eip" {
  domain = "vpc"

  tags = {
    Name = "cloudzenia-nat-eip"
  }
}

resource "aws_nat_gateway" "cloudzenia_nat" {
  allocation_id = aws_eip.cloudzenia_nat_eip.id
  subnet_id     = aws_subnet.cloudzenia_public_1.id

  depends_on = [aws_internet_gateway.cloudzenia_igw]

  tags = {
    Name = "cloudzenia-nat-gateway"
  }
}

# route tables
resource "aws_route_table" "cloudzenia_public_rt" {
  vpc_id = aws_vpc.cloudzenia_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.cloudzenia_igw.id
  }

  tags = {
    Name = "cloudzenia-public-rt"
  }
}

resource "aws_route_table" "cloudzenia_private_rt" {
  vpc_id = aws_vpc.cloudzenia_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.cloudzenia_nat.id
  }

  tags = {
    Name = "cloudzenia-private-rt"
  }
}

# route table associations
resource "aws_route_table_association" "public_1_assoc" {
  subnet_id      = aws_subnet.cloudzenia_public_1.id
  route_table_id = aws_route_table.cloudzenia_public_rt.id
}

resource "aws_route_table_association" "public_2_assoc" {
  subnet_id      = aws_subnet.cloudzenia_public_2.id
  route_table_id = aws_route_table.cloudzenia_public_rt.id
}

resource "aws_route_table_association" "private_1_assoc" {
  subnet_id      = aws_subnet.cloudzenia_private_1.id
  route_table_id = aws_route_table.cloudzenia_private_rt.id
}

resource "aws_route_table_association" "private_2_assoc" {
  subnet_id      = aws_subnet.cloudzenia_private_2.id
  route_table_id = aws_route_table.cloudzenia_private_rt.id
}

# security group
resource "aws_security_group" "cloudzenia_sg" {
  name   = "cloudzenia-sg"
  vpc_id = aws_vpc.cloudzenia_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "cloudzenia-sg"
  }
}

# ec2 instances
resource "aws_instance" "public_ec2_1" {
  ami                         = "ami-06f1fc9ae5ae7f31e"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.cloudzenia_public_1.id
  key_name                    = "Cloud-Zenia"
  vpc_security_group_ids      = [aws_security_group.cloudzenia_sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "cloudzenia-public-ec2-1"
  }
}

resource "aws_instance" "public_ec2_2" {
  ami                         = "ami-06f1fc9ae5ae7f31e"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.cloudzenia_public_2.id
  key_name                    = "Cloud-Zenia"
  vpc_security_group_ids      = [aws_security_group.cloudzenia_sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "cloudzenia-public-ec2-2"
  }
}

resource "aws_instance" "private_ec2_1" {
  ami                    = "ami-06f1fc9ae5ae7f31e"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.cloudzenia_private_1.id
  key_name               = "Cloud-Zenia"
  vpc_security_group_ids = [aws_security_group.cloudzenia_sg.id]

  tags = {
    Name = "cloudzenia-private-ec2-1"
  }
}

resource "aws_instance" "private_ec2_2" {
  ami                    = "ami-06f1fc9ae5ae7f31e"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.cloudzenia_private_2.id
  key_name               = "Cloud-Zenia"
  vpc_security_group_ids = [aws_security_group.cloudzenia_sg.id]

  tags = {
    Name = "cloudzenia-private-ec2-2"
  }
}

# application load balancer
resource "aws_lb" "cloudzenia_alb" {
  name               = "ALB-CZ"
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.cloudzenia_sg.id]

  subnets = [
    aws_subnet.cloudzenia_public_1.id,
    aws_subnet.cloudzenia_public_2.id
  ]

  tags = {
    Name = "ALB-CZ"
  }
}

# target groups
resource "aws_lb_target_group" "tg_1" {
  name        = "TG-1"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.cloudzenia_vpc.id
  target_type = "instance"

  health_check {
    path = "/"
  }
}

resource "aws_lb_target_group" "tg_2" {
  name        = "TG-2"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.cloudzenia_vpc.id
  target_type = "instance"

  health_check {
    path = "/"
    port = "8080"
  }
}

# target group attachments
resource "aws_lb_target_group_attachment" "tg1_attach" {
  target_group_arn = aws_lb_target_group.tg_1.arn
  target_id        = aws_instance.private_ec2_1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "tg2_attach" {
  target_group_arn = aws_lb_target_group.tg_2.arn
  target_id        = aws_instance.private_ec2_2.id
  port             = 8080
}

# alb listener
resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.cloudzenia_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_1.arn
  }
}

# listener rule
resource "aws_lb_listener_rule" "tg2_rule" {
  listener_arn = aws_lb_listener.alb_listener.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_2.arn
  }

  condition {
    path_pattern {
      values = ["/app2*"]
    }
  }
}
