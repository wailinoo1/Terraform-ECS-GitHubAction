output "tgb_ecs_arn" {
  value = aws_lb_target_group.ecs-tgb.arn
}

output "ecs_sg_id" {
  value = aws_security_group.ecs-sg.id
}