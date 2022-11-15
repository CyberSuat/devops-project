# show provider amazon's latest version and region in the terraform
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.38.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# show amazon linux ami
data "aws_ami" "amazon-linux-2" {
  owners      = ["amazon"]
  most_recent = true

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

}
# show default aws vpc and subnet

data "aws_vpc" "default-vpc" {
  default = "true"
  
}
data "aws_subnets" "default-subnets" {
  filter {
    name = "vpc-id"
    values = [data.aws_vpc.default-vpc_id]

  }
}
  
resource "aws_db_instance" "project-rds" {
  allocated_storage    = 10
  db_name              = "phonebook"
  engine               = "MySQL"
  engine_version       = "8.0.25"
  instance_class       = "db.t2.micro"
  username = "Admin"
  password = "Suat_123"
  port = 3306
  vpc_security_group_ids = [aws_security_group.sg-rds.id]
  
}
output "rds_endpoint" {
  value = aws_db_instance.project-rds.endpoint 
}

resource "aws_lb" "project-lb" {
  name               = "project-lb-tf"
  load_balanscer_type = "application"
  security_groups    = [aws_security_group.sg-lb.id]
  enable_deletion_protection = true
  subnets = data.aws_subnets.default-subnets.id
}
resource "aws_lb_target_group" "alb-target" {
  name        = "tf-aws-lb-alb-tg"
  target_type = "instance"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default-vpc.id
  health_check {
    unhealthy_threshold = 3
    healthy_threshold = 2
  }
}
resource "aws_lb_listener" "listener-lb" {
  load_balancer_arn = aws_lb.project-lb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb-target.arn
  }
}

data "template_file" "userdata" {
  template = file("${abspath(path.module)}/userdata.sh")
  vars = {
    server-name = var.server-name
  }
}

resource "aws_launch_template" "launch_template" {
  image_id = data.aws_ami.amazon-linux-2.id
  instance_type = var.instance_type
  key_name = var.key_name
  vpc_security_group_ids = aws_security_group.sg-instance.id
  userdata = data.template_file.launch_template.rendered
  
}

resource "aws_autoscaling_group" "project-asc" {
  name                      = "project-asc"
  max_size                  = 3
  min_size                  = 1
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 2
  target_group_arn = aws_lb_target_group.alb-target.arn
  launch_template {
    id = aws_launch_template.launch_template.id
  }
 
}

resource "aws_instance" "tf-1" {
  ami           = data.aws_ami.amazon-linux-2.id
  instance_type = var.instance_type
  key_name      = var.key_name
  security_groups = aws_security_group.sg-instance.id
  tags = {
    "Name" = var.tag
  }
}
