# TODO: Implement this module.
# Read the README.md in this directory for the full list of resources to create.
# Refer to the Terraform documentation: https://registry.terraform.io/providers/hashicorp/aws/latest/docs

resource "aws_security_group" "alb" {
  name        = "lks-sg-alb"
  description = "Attached to the Application Load Balancer."
  vpc_id      = var.vpc_id

  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "lks-sg-alb"
  }
}

resource "aws_security_group" "ecs" {
  name        = "lks-sg-ecs"
  description = "Attached to all ECS Fargate tasks in lks-vpc."
  vpc_id      = var.vpc_id

  ingress {
    from_port        = 3000
    to_port          = 3000
    protocol         = "tcp"
    security_groups      = [aws_security_group.alb.id]
  }

  ingress {
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    security_groups      = [aws_security_group.alb.id]
  }

  ingress {
    from_port        = 5000
    to_port          = 5000
    protocol         = "tcp"
    security_groups      = [aws_security_group.alb.id]
  }

  ingress {
    from_port        = 9100
    to_port          = 9100
    protocol         = "tcp"
    cidr_blocks      = ["10.1.0.0/16"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "lks-sg-ecs"
  }
}

resource "aws_security_group" "db" {
  name        = "lks-sg-db"
  description = "Attached to RDS instance."
  vpc_id      = var.vpc_id

  ingress {
    from_port        = 5432
    to_port          = 5432
    protocol         = "tcp"
    security_groups      = [aws_security_group.ecs.id]
  }

  ingress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    security_groups      = [aws_security_group.ecs.id]
  }

  tags = {
    Name = "lks-sg-db"
  }
}

resource "aws_security_group" "monitoring" {
  name        = "lks-sg-monitoring"
  description = "Attached to all monitoring ECS tasks in lks-monitoring-vpc."
  vpc_id      = var.vpc_id

  ingress {
    from_port        = 9090
    to_port          = 9090
    protocol         = "tcp"
    self       = true
  }

  ingress {
    from_port        = 3000
    to_port          = 3000
    protocol         = "tcp"
    cidr_blocks      = ["10.0.0.0/16"]
  }

  ingress {
    from_port        = 3100
    to_port          = 3100
    protocol         = "tcp"
    self       = true
  }

  ingress {
    from_port        = 9093
    to_port          = 9093
    protocol         = "tcp"
    self       = true
  }
  
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "lks-sg-monitoring"
  }
}