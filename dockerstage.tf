#Create Docker Server
resource "aws_instance" "client3_docker_stage" {
  ami                    = "ami-01daacddaafcdd876"
  instance_type          = "t2.medium"
  vpc_security_group_ids = [aws_security_group.client3_docker_sg.id]
  key_name               = aws_key_pair.client3_pub_key.key_name
  subnet_id              = aws_subnet.client3_prv_sn1.id
  user_data              = local.docker_user_data

  tags = {
    Name = "client3_docker_stage"
  }
}

data "aws_instance" "client3_docker_stage" {
  filter {
    name   = "tag:Name"
    values = ["client3_docker_stage"]
  }
  depends_on = [
    aws_instance.client3_docker_stage
  ]
}