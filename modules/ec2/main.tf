resource "aws_launch_configuration" "example" {
  name          = "${var.cluster_name}-${var.environment}"
  image_id      = var.ami # AMI untuk Amazon Linux 2 di ap-southeast-1, ganti sesuai kebutuhan
  instance_type = var.instance_type # Tipe instance

  key_name = var.key_pair
  security_groups = [ aws_security_group.web_service.id ]
  associate_public_ip_address = false

  
  user_data = <<-EOF
                #!/bin/bash
                apt-get update -y
                apt-get install -y python3
                echo "Hello, World!" > index.html
                nohup python3 -m http.server 80 &
                EOF
                
  lifecycle {
    create_before_destroy = false
  }
}

resource "aws_autoscaling_group" "web_service" {
  launch_configuration = aws_launch_configuration.example.id
  target_group_arns    = [aws_lb_target_group.web_service.arn]
  min_size             = var.instance_min_count
  max_size             = var.instance_max_count
  health_check_type    = "ELB"

  # availability_zones   = var.asg_availability_zones
  vpc_zone_identifier  = var.subnets # Pastikan subnet ini ada di VPC yang sama dengan Security Group
  tag {
    key                 = "Name"
    value               = "web-instance-${var.environment}"
    propagate_at_launch = true
  }
}

resource "aws_security_group" "web_service" {
  name = "${var.cluster_name}-${var.environment}-alb"
  vpc_id = var.vpc_id

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

resource "aws_lb" "web_service" {
  name               = "${var.cluster_name}-${var.environment}-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web_service.id]
  subnets            = var.subnets

}

resource "aws_lb_target_group" "web_service" {
  name     = "${var.cluster_name}-${var.environment}-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
}

resource "aws_lb_listener" "web_service" {
  load_balancer_arn = aws_lb.web_service.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_service.arn
  }
}