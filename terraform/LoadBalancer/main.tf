resource "aws_s3_bucket" "ecs-alb-logs" {
  bucket = var.ecs-alblogs3
  tags = {
    Name        = "${var.ecs-alblogs3}"
  }
}

resource "aws_s3_bucket_policy" "alb_access_logs_policy" {
  bucket = aws_s3_bucket.ecs-alb-logs.bucket

  policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::114774131450:root"
      },
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::${var.ecs-alblogs3}/*"
    }
  ]
})
}
resource "aws_security_group" "ecs-sg" {
  name   = var.ecs_sg_name
  vpc_id = var.vpcid
  
  ingress{
      from_port        = 8080
      to_port          = 8080
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
  }
  ingress{
      from_port        = 80
      to_port          = 80
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
  }
  egress {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
  }
}


resource "aws_lb" "terraform-alb" {
  name               = var.alb-name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ecs-sg.id]
  subnets            = [for subnet in var.public-subnetid : subnet]
 

  enable_deletion_protection = false

     access_logs {
      bucket  = aws_s3_bucket.ecs-alb-logs.id
      enabled = true
    }

  tags = {
    Environment = "${var.alb-name}"
  }
}


resource "aws_lb_target_group" "ecs-tgb" {
  name        = var.ecs_tgb_name
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpcid
}

resource "aws_lb_listener" "listen80" {
  load_balancer_arn = aws_lb.terraform-alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs-tgb.arn
  }
  depends_on = [ aws_lb.terraform-alb , aws_lb_target_group.ecs-tgb]
}