# creating docker target group
resource "aws_lb_target_group" "client3-docker-prod-tg" {
  name     = "client3-docker-prod"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.client3_vpc.id
}
#creating docker prod load balancer target group attachment
resource "aws_lb_target_group_attachment" "client3_docker_prod_tg_attachment" {
  target_group_arn = aws_lb_target_group.client3-docker-prod-tg.arn
  target_id        = aws_instance.client3_docker_prod.id
  port             = 8080
}

# creating docker load balancer
resource "aws_lb" "client3-docker-prod-lb" {
  name               = "client3-docker-prod-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.client3_docker_prod_lb_sg.id]
  subnets            = [aws_subnet.client3_pub_sn1.id, aws_subnet.client3_pub_sn2.id]

  enable_deletion_protection = false


  tags = {
    Environment = "production"
  }
}
#creating load balancer listener
resource "aws_lb_listener" "client3-docker-prod-listener" {
  load_balancer_arn = aws_lb.client3-docker-prod-lb.arn
  port              = "80"
  protocol          = "HTTP"


  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.client3-docker-prod-tg.arn
  }
}

#creating docker prod security group 
resource "aws_security_group" "client3_docker_prod_lb_sg" {
  name        = "client3_docker_prod_lb_sg"
  description = "Allow Docker traffic"
  vpc_id      = aws_vpc.client3_vpc.id

  ingress {
    description = "Proxy Traffic"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "client3_docker_prod_lb_sg"
  }
}


