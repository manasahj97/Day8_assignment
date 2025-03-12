provider "aws" {
  region = "us-east-1"
}

# VPC Module
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  name   = "my-vpc"
  cidr   = "10.0.0.0/16"
  
  azs             = ["us-east-1a", "us-east-1b"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.3.0/24", "10.0.4.0/24"]
  enable_nat_gateway = true
}

# Security Groups
resource "aws_security_group" "alb_sg" {
  vpc_id = module.vpc.vpc_id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ALB
resource "aws_lb" "app_alb" {
  name               = "app-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = module.vpc.public_subnets
}

# Auto Scaling Group
resource "aws_launch_template" "app" {
  name_prefix   = "app-launch-template-"
  image_id      = "ami-0abcdef1234567890"
  instance_type = "t3.micro"
}

resource "aws_autoscaling_group" "app_asg" {
  vpc_zone_identifier = module.vpc.private_subnets
  desired_capacity    = 2
  max_size           = 4
  min_size           = 2
  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }
}

# S3 for Static Content
resource "aws_s3_bucket" "static_content" {
  bucket = "my-static-content-bucket"
}

resource "aws_s3_bucket_public_access_block" "static_content" {
  bucket                  = aws_s3_bucket.static_content.id
  block_public_acls       = false
  block_public_policy     = false
  restrict_public_buckets = false
  ignore_public_acls      = false
}

resource "aws_s3_bucket_policy" "public_read" {
  bucket = aws_s3_bucket.static_content.id
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::my-static-content-bucket/*"
    }
  ]
}
POLICY
}


# RDS Database
module "rds" {
  source = "terraform-aws-modules/rds/aws"
  identifier = "mydb"
  engine     = "mysql"
  engine_version = "8.0"
  instance_class  = "db.t3.medium"
  allocated_storage = 20
  multi_az         = true
  username         = "admin"
  password         = "password123"
  vpc_security_group_ids = [aws_security_group.alb_sg.id]
  db_subnet_group_name   = module.vpc.default_subnet_group
}

# CloudWatch Monitoring
resource "aws_cloudwatch_log_group" "app_logs" {
  name = "/aws/app/logs"
}

# IAM Role
resource "aws_iam_role" "ecs_instance_role" {
  name = "ecs-instance-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

output "alb_dns_name" {
  value = aws_lb.app_alb.dns_name
}

