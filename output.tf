# Output for Security Group
output "attendance_security_group_id" {
  description = "The ID of the security group for the attendance application"
  value       = aws_security_group.attendance-sg.id
}

# Output for Launch Template
output "attendance_launch_template_id" {
  description = "The ID of the launch template for the attendance application"
  value       = aws_launch_template.attendance-launch-template.id
}

# Output for Target Group
output "attendance_target_group_arn" {
  description = "The ARN of the target group for the attendance application"
  value       = aws_lb_target_group.attendance-tg.arn
}

# Output for Auto Scaling Group
output "attendance_asg_name" {
  description = "The name of the Auto Scaling Group for the attendance application"
  value       = aws_autoscaling_group.attendance-asg.name
}

# Output for Subnets
output "application_subnet_ids" {
  description = "The IDs of the application subnets"
  value       = aws_subnet.application[*].id
}

# Output for VPC
output "vpc_id" {
  description = "The ID of the VPC for the attendance application"
  value       = aws_vpc.OT-micro.id
}
