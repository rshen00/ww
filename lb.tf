resource "aws_lb" "ww" {
  name               = "ww-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [for s in data.aws_subnet.public : s.id]
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.ww.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.AWS_ACM_CERT_ARN

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ww.arn
  }
}

# Setup the target_group
# Also add health_check to enhance the resiliency
#   - Asssume the health check service is on the path of "/health"
#   - Set 200 as the successful response
#   - Use all default for the rest
resource "aws_lb_target_group" "ww" {
  name     = "ww-target-group"
  port     = 8192
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.main.id

  lifecycle { 
    create_before destroy = true
  }

  health_check {
    path = "/health"
    port = 8192
    matcher = 200
  }
}
