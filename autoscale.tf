
resource "aws_instance" "web" {
  ami = var.ami
  instance_type = var.instance_type
  key_name = var.key_name
  security_groups = var.security_groups
  availability_zone = "us-east-2a"
  user_data = file("install_httpd.sh")
}

resource "aws_ami_from_instance" "zon-image" {
  name               = "zon-image"
  source_instance_id = aws_instance.web.id

  depends_on = [aws_instance.web]
}

resource "aws_launch_template" "zon-auto-lt" {
  name = "zon-auto-lt"
  image_id = aws_ami_from_instance.zon-image.id
  instance_type = var.instance_type
  security_group_names = var.security_groups
  key_name = var.key_name

  depends_on = [aws_ami_from_instance.zon-image]
}

# Create a new load balancer
resource "aws_elb" "zon-elb" {
  name               = "zon-elb"
  availability_zones = ["us-east-2a", "us-east-2b", "us-east-2c"]
  security_groups = ["sg-0ab0134dd0351c2fa"]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/index.html"
    interval            = 30
  }

  cross_zone_load_balancing   = true
  idle_timeout                = 100
  connection_draining         = true
  connection_draining_timeout = 300

}

resource "aws_autoscaling_group" "zon-asg" {
  desired_capacity = 2
  max_size = 4
  min_size = 2

  availability_zones = ["us-east-2a", "us-east-2b", "us-east-2c"]

  launch_template {
    id = aws_launch_template.zon-auto-lt.id
  }

  depends_on = [aws_launch_template.zon-auto-lt]

}

resource "aws_autoscaling_attachment" "asg-attachment-lb" {
  autoscaling_group_name = aws_autoscaling_group.zon-asg.id
  elb = aws_elb.zon-elb.id

  depends_on = [aws_autoscaling_group.zon-asg, aws_elb.zon-elb]
}

resource "aws_autoscaling_notification" "asg-notification" {
  topic_arn = "arn:aws:sns:us-east-2:851362555785:autoscaling_topic"
  group_names = [aws_autoscaling_group.zon-asg.id]
  notifications = [
    "autoscaling:EC2_INSTANCE_LAUNCH",
    "autoscaling:EC2_INSTANCE_TERMINATE",
    "autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
    "autoscaling:EC2_INSTANCE_TERMINATE_ERROR",
  ]

  depends_on = [aws_autoscaling_group.zon-asg]
}

resource "aws_autoscaling_policy" "avg_cpu_gt_5_policy" {
  autoscaling_group_name = aws_autoscaling_group.zon-asg.id
  name                   = "avg_cpu_gt_5_policy"
  policy_type = "TargetTrackingScaling"
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 5.0
  }

  depends_on = [aws_autoscaling_group.zon-asg]
}

output "elb-dns-name" {
  value = aws_elb.zon-elb.dns_name
}