output "monitoring_vpc_id"            { value = aws_vpc.main.id }
output "monitoring_subnet_ids"        { value = [aws_subnet.private_a.id, aws_subnet.private_b.id] }
output "monitoring_security_group_id" { value = aws_security_group.endpoint.id }
output "monitoring_rt"                { value = aws_route_table.private.id }
output "vpc_peering_connection_id"    { value = "" }
