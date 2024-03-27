provider "aws" {
  region = var.aws_region
}

data "aws_vpc" "main" {
  id = var.AWS_VPC_ID
}

data "aws_subnets" "private" {
  filter {
    name = var.AWS_VPC_ID
    values = [
      var.AWS_SUBNET_A,
      var.AWS_SUBNET_B,
      var.AWS_SUBNET_C,
      var.AWS_SUBNET_D
    ]
  }
}

data "aws_subnets" "public" {
  filter {
    name = var.AWS_VPC_ID
    values = [
      var.AWS_PUBLIC_SUBNET_A,
      var.AWS_PUBLIC_SUBNET_B,
      var.AWS_PUBLIC_SUBNET_C,
      var.AWS_PUBLIC_SUBNET_D
    ]
  }
}

data "aws_subnet" "private" {
  for_each = toset(data.aws_subnets.private.ids)
  id       = each.value
}

data "aws_subnet" "public" {
  for_each = toset(data.aws_subnets.public.ids)
  id       = each.value
}

resource "aws_internet_gateway" "main" {
  vpc_id = data.aws_vpc.main.id
}

resource "aws_route_table" "public" {
  vpc_id = data.aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}

resource "aws_route_table_association" "public" {
  count = length(data.aws_subnet.public)

  subnet_id      = [for s in data.aws_subnet.public : s.id]
  route_table_id = aws_route_table.public.id
}

resource "aws_launch_template" "ww" {
  name_prefix   = "ww-"
  image_id      = var.AWS_AMI_ID
  instance_type = "t3a.xlarge"

  block_device_mappings {
    device_name = "/dev/sda"

    ebs {
      volume_type = "gp3"
      volume_size = 500
      throughput  = 250
    }
  }

  vpc_security_group_ids = [aws_security_group.instance_sg.id]
}

resource "aws_autoscaling_group" "ww" {
  launch_template {
    id      = aws_launch_template.ww.id
    version = "$Latest"
  }

  min_size            = 2
  max_size            = 10
  desired_capacity    = 5
  vpc_zone_identifier = [for s in data.aws_subnet.private : s.id]

  target_group_arns = [aws_lb_target_group.ww.arn]
}

# Set autoscaling policy to scale if cpu utilization is above 50
resource "aws_autoscaling_policy" "avg_cpu_policy_greater_than_50" {
  name                      = "avg-cpu-policy-greater-than-50"
  policy_type               = "TargetTrackingScaling"
  autoscaling_group_name    = aws_autoscaling_group.main.id
  estimated_instance_warmup = 180
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 50.0
  }
}

