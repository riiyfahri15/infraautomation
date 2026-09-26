provider "aws" {
    alias  = "oregon"
    region = "us-west-2"
}

resource "aws_vpc_peering_connection" "main" {
  peer_owner_id = var.account_id
  peer_vpc_id   = var.monitoring_vpc
  vpc_id        = var.vpc_app
  peer_region   = "us-west-2"
  
  tags = {
    Name = "pcx-lks-2026"
  }

}

resource "aws_vpc_peering_connection_accepter" "main" {
  provider                  = aws.oregon
  vpc_peering_connection_id = aws_vpc_peering_connection.main.id
  auto_accept               = true

  tags = {
    Side = "Accepter"
  }
}

resource "aws_route" "route_vpc" {
  route_table_id            = var.vpc_rt
  destination_cidr_block    = "10.1.0.0/16"
  vpc_peering_connection_id = aws_vpc_peering_connection.main.id
}

resource "aws_route" "monitoring_vpc" {
  provider                  = aws.oregon
  route_table_id            = var.monitoring_rt
  destination_cidr_block    = "10.0.0.0/16"
  vpc_peering_connection_id = aws_vpc_peering_connection.main.id
}
