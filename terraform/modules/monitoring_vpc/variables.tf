variable "monitoring_vpc_cidr"          { type = string }
variable "monitoring_subnet_cidrs"      { type = list(string) }
variable "availability_zones"           { type = list(string) }
variable "app_vpc_id"                   { type = string }
variable "app_vpc_cidr"                 { type = string }
variable "app_private_route_table_id"   { type = string }
