# TODO: Implement this module.
# Read the README.md in this directory for the full list of resources to create.
# Refer to the Terraform documentation: https://registry.terraform.io/providers/hashicorp/aws/latest/docs

provider "aws" {
    alias  = "oregon"
    region = "us-west-2"
}

resource "aws_vpc" "main" {
  provider = aws.oregon
  cidr_block = "10.1.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true
  
  tags = {
    Name = "lks-monitoring-vpc"
  }
}

resource "aws_subnet" "private_a" {
  provider = aws.oregon
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.1.1.0/24"
  availability_zone = "us-west-2a"

  tags = {
    Name = "lks-monitoring-private-1a"
  }
}

resource "aws_subnet" "private_b" {
  provider = aws.oregon
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.1.2.0/24"
  availability_zone = "us-west-2b"

  tags = {
    Name = "lks-monitoring-private-1b"
  }
}

resource "aws_route_table" "private" {
  provider = aws.oregon
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "lks-private-rt"
  }
}

resource "aws_route_table_association" "private_a" {
  provider = aws.oregon
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_b" {
  provider = aws.oregon
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private.id
}

resource "aws_security_group" "endpoint" {
  provider = aws.oregon
  name        = "lks-sg-endpoint"
  description = "Attached to endpoint monitoring ECS tasks in lks-monitoring-vpc."
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port        = 443
    to_port          = 443
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
    Name = "lks-sg-endpoint"
  }
}

resource "aws_vpc_endpoint" "ssm" {
  provider = aws.oregon
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.us-west-2.ssm"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.endpoint.id,
  ]

  subnet_ids = [
    aws_subnet.private_a.id, aws_subnet.private_b.id
  ]

  private_dns_enabled = true

  tags = {
    Environment = "lks-endpoint-ssm"
  }
}

resource "aws_vpc_endpoint" "ssmmessages" {
  provider = aws.oregon
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.us-west-2.ssmmessages"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.endpoint.id,
  ]

  subnet_ids = [
    aws_subnet.private_a.id, aws_subnet.private_b.id
  ]

  private_dns_enabled = true

  tags = {
    Environment = "lks-endpoint-ssmmessages"
  }
}

resource "aws_vpc_endpoint" "ec2messages" {
  provider = aws.oregon
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.us-west-2.ec2messages"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.endpoint.id,
  ]

  subnet_ids = [
    aws_subnet.private_a.id, aws_subnet.private_b.id
  ]

  private_dns_enabled = true

  tags = {
    Environment = "lks-endpoint-ec2messages"
  }
}

resource "aws_vpc_endpoint" "logs" {
  provider = aws.oregon
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.us-west-2.logs"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.endpoint.id,
  ]

  subnet_ids = [
    aws_subnet.private_a.id, aws_subnet.private_b.id
  ]

  private_dns_enabled = true

  tags = {
    Environment = "lks-endpoint-logs"
  }
}

resource "aws_vpc_endpoint" "ecr_api" {
  provider = aws.oregon
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.us-west-2.ecr.api"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.endpoint.id,
  ]

  subnet_ids = [
    aws_subnet.private_a.id, aws_subnet.private_b.id
  ]

  private_dns_enabled = true

  tags = {
    Environment = "lks-endpoint-ecr.api"
  }
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  provider = aws.oregon
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.us-west-2.ecr.dkr"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.endpoint.id,
  ]

  subnet_ids = [
    aws_subnet.private_a.id, aws_subnet.private_b.id
  ]

  private_dns_enabled = true

  tags = {
    Environment = "lks-endpoint-ecr.dkr"
  }
}

resource "aws_vpc_endpoint" "ecs" {
  provider = aws.oregon
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.us-west-2.ecs"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.endpoint.id,
  ]

  subnet_ids = [
    aws_subnet.private_a.id, aws_subnet.private_b.id
  ]

  private_dns_enabled = true

  tags = {
    Environment = "lks-endpoint-ecs"
  }
}

resource "aws_vpc_endpoint" "ecs_agent" {
  provider = aws.oregon
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.us-west-2.ecs-agent"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.endpoint.id,
  ]

  subnet_ids = [
    aws_subnet.private_a.id, aws_subnet.private_b.id
  ]

  private_dns_enabled = true

  tags = {
    Environment = "lks-endpoint-ecs-agent"
  }
}

resource "aws_vpc_endpoint" "ecs_telemetry" {
  provider = aws.oregon
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.us-west-2.ecs-telemetry"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.endpoint.id,
  ]

  subnet_ids = [
    aws_subnet.private_a.id, aws_subnet.private_b.id
  ]

  private_dns_enabled = true

  tags = {
    Environment = "lks-endpoint-ecs-telemetry"
  }
}

resource "aws_vpc_endpoint" "monitoring" {
  provider = aws.oregon
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.us-west-2.monitoring"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.endpoint.id,
  ]

  subnet_ids = [
    aws_subnet.private_a.id, aws_subnet.private_b.id
  ]

  private_dns_enabled = true

  tags = {
    Environment = "lks-endpoint-monitoring"
  }
}

resource "aws_vpc_endpoint" "s3" {
  provider = aws.oregon
  vpc_id         = aws_vpc.main.id
  service_name   = "com.amazonaws.us-west-2.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [
    aws_route_table.private.id
  ]

  tags = {
    Environment = "lks-endpoint-s3"
  }
}
