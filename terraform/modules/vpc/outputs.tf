output "vpc_id"               { value = aws_vpc.main.id }
output "public_subnet_ids"   { value = [aws_subnet.public_a.id, aws_subnet.public_b.id] }
output "private_subnet_ids"  { value = [aws_subnet.private_a.id, aws_subnet.private_b.id] }
output "isolated_subnet_ids" { value = [aws_subnet.isolated_a.id, aws_subnet.isolated_b.id] }
output "private_route_table_id" { value = aws_route_table.private.id }
