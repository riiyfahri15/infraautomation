output "alb_dns_name"       { value = aws_lb.main.dns_name }
output "alb_zone_id"        { value = aws_lb.main.zone_id }
output "tg_fe_arn"          { value = aws_lb_target_group.fe.arn }
output "tg_api_arn"         { value = aws_lb_target_group.api.arn }
output "tg_analytics_arn"   { value = aws_lb_target_group.analytics.arn }