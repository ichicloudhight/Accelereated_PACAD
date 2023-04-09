# #Add High Availability

# # Create DockerHost AMI 
# resource "aws_ami_from_instance" "client3_docker_prod" {
#   name               = "client3_docker_prod"
#   source_instance_id = aws_instance.client3_docker_prod.id
#   snapshot_without_reboot = true

#   depends_on = [
#     aws_instance.client3_docker_prod
#   ]

#   tags = {
#     name = "client3_docker_AMI"
#   }
# }



# #Create launch template
# resource "aws_launch_template" "client3-lt" {
#   name_prefix                 = "client3-lt"
#   image_id                    = aws_ami_from_instance.client3_docker_prod.id
#   instance_type               = "t2.micro"
  
#   key_name                    = aws_key_pair.PACADEU1_pub_key.key_name

#   monitoring {
#     enabled = false
# }

#   network_interfaces{
#   associate_public_ip_address = true
#   security_groups             = [aws_security_group.client3_docker_sg.id]
#   }

# }

# # Create Autoscaling group
# resource "aws_autoscaling_group" "client3-asg" {
#   name                      = "client3-asg"
  
#   max_size                  = 5
#   min_size                  = 2
#   health_check_grace_period = 300
#   default_cooldown          = 60
#   health_check_type         = "EC2"
#   desired_capacity          = 2
#   force_delete              = true
#   vpc_zone_identifier       = [aws_subnet.client3_prv_sn1.id, aws_subnet.client3_prv_sn2.id]
#   target_group_arns         = ["${aws_lb_target_group.pacadeu1-docker-prod-tg.arn}"]
 
# launch_template {
#     id                      = aws_launch_template.client3-lt.id
#     version                 = "$Latest"
# }

# tag {
#     key                 = "Name"
#     value               = "client3-asg"
#     propagate_at_launch = true
#   }
# }

# # create Autoscaling group policy
# resource "aws_autoscaling_policy" "client3-asg-pol" {
#   name                   = "client3-asg-pol"
#   policy_type            = "TargetTrackingScaling"
#   adjustment_type        = "ChangeInCapacity"
#   autoscaling_group_name = aws_autoscaling_group.client3-asg.name
#   target_tracking_configuration {
#     predefined_metric_specification {
#       predefined_metric_type = "ASGAverageCPUUtilization"
#     }
#     target_value = 40
#   }
# } 
