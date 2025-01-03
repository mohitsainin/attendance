 # VPC
 resource "aws_vpc" "OT-micro" {
   cidr_block = var.vpc_CIDR
  tags = {
    Name = "OT-micro-VPC"
  }
}

# # Internet Gateway
resource "aws_internet_gateway" "OT-micro-igw" {
   vpc_id = aws_vpc.OT-micro.id
  tags = {
    Name = "OT-micro-IGW"
  }
 }

# # Public Route Table
 resource "aws_route_table" "OT-micro-public-rt" {
   vpc_id = aws_vpc.OT-micro.id
   tags = {
    Name = "OT-micro-Public-RT"
   }
 }

# # Route for Internet Gateway
 resource "aws_route" "OT-micro-public-route" {
   route_table_id         = aws_route_table.OT-micro-public-rt.id
  destination_cidr_block = "0.0.0.0/0"
   gateway_id             = aws_internet_gateway.OT-micro-igw.id
 }

 # Subnets
 resource "aws_subnet" "application" {
   count             = 2
   vpc_id            = aws_vpc.OT-micro.id
   cidr_block        = var.Application_subnet_cidr[count.index]
  availability_zone = var.availability_zones[count.index]
   map_public_ip_on_launch = true
   tags = {
     Name = "application-subnet-${count.index + 1}"
     Type = "application"
   }
 }

# # Associate Subnets with Route Table
 resource "aws_route_table_association" "public_association" {
   count          = 2
   subnet_id      = aws_subnet.application[count.index].id
   route_table_id = aws_route_table.OT-micro-public-rt.id
 }

# Security Group
resource "aws_security_group" "attendance-sg" {
  vpc_id = aws_vpc.OT-micro.id

  ingress {
    from_port   = 22
    to_port     = 22
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
    Name = "attendance-sg"
    ENV  = "dev"
  }
}

# # Load Balancer
 resource "aws_lb" "my_alb" {
   name               = "my-alb"
   internal           = false
   load_balancer_type = "application"
   security_groups    = [aws_security_group.attendance-sg.id]
   subnets            = aws_subnet.application[*].id

   tags = {
     Name = "OT-micro-ALB"
   }
 }

# ALB Listener
resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.my_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Default response"
      status_code  = "200"
    }
  }
}

# Launch Template
resource "aws_launch_template" "attendance-launch-template" {
  name_prefix   = "attendance-launch-template"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  network_interfaces {
    associate_public_ip_address = false
    subnet_id                   = aws_subnet.application[0].id
    security_groups             = [aws_security_group.attendance-sg.id]
  }
}

# Target Group
resource "aws_lb_target_group" "attendance-tg" {
  name     = "attendance-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.OT-micro.id

  health_check {
    interval            = 30
    path                = "/actuator/health"
    protocol            = "HTTP"
    timeout             = 2
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "attendance-asg" {
  name                = "attendance-asg"
  desired_capacity    = 2
  max_size            = 4
  min_size            = 1
  vpc_zone_identifier = [aws_subnet.application[0].id, aws_subnet.application[1].id]

  launch_template {
    id      = aws_launch_template.attendance-launch-template.id
    version = "$Latest"
  }

  health_check_type         = "EC2"
  health_check_grace_period = 300
  force_delete              = true
  wait_for_capacity_timeout = "0"

  target_group_arns = [aws_lb_target_group.attendance-tg.arn]

  tag {
    key                 = "Name"
    value               = "attendance-instance"
    propagate_at_launch = true
  }
}

# ALB Listener Rule
resource "aws_lb_listener_rule" "attendance_rule" {
  listener_arn = aws_lb_listener.http_listener.arn
  priority     = 3

  condition {
    path_pattern {
      values = ["/attendance-documentation", "/swagger-ui/*", "/api/v1/attendance/*", "/actuator/*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.attendance-tg.arn
  }
}

# Auto Scaling Policy
resource "aws_autoscaling_policy" "attendance-autoscaling-policy" {
  name                   = "attendance-asg-policy"
  policy_type            = "TargetTrackingScaling"
  estimated_instance_warmup = 300
  autoscaling_group_name = aws_autoscaling_group.attendance-asg.name

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 50.0
  }
}
