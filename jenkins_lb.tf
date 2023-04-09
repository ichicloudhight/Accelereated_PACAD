# creating jenkins target group
resource "aws_lb_target_group" "client3-jenkins-tg" {
  name     = "client3-jenkins-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.client3_vpc.id
}
#creating jenkins load balancer target group attachment
resource "aws_lb_target_group_attachment" "client3_jenkins_lb_tg_attachment" {
  target_group_arn = aws_lb_target_group.client3-jenkins-tg.arn
  target_id        = aws_instance.client3_Jenkins.id
  port             = 8080
}

# creating jenkins load balancer
resource "aws_lb" "client3-jenkins-lb" {
  name               = "client3-jenkins-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.client3_jenkins_lb_sg.id]
  subnets            = [aws_subnet.client3_pub_sn1.id, aws_subnet.client3_pub_sn2.id]

  enable_deletion_protection = false


  tags = {
    Environment = "production"
  }
}
#creating load balancer listener
resource "aws_lb_listener" "client3_listener" {
  load_balancer_arn = aws_lb.client3-jenkins-lb.arn
  port              = "80"
  protocol          = "HTTP"


  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.client3-jenkins-tg.arn
  }
}

#creating jenkins security group 
resource "aws_security_group" "client3_jenkins_lb_sg" {
  name        = "client3_jenkins_lb_sg"
  description = "Allow Jenkins traffic"
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
    Name = "client3_jenkins_lb_sg"
  }
}


