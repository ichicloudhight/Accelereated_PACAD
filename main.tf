# create KeyPair 
resource "tls_private_key" "client3_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "client3_prv" {
  content  = tls_private_key.client3_key.private_key_pem
  filename = "client3_prv"
}


resource "aws_key_pair" "client3_pub_key" {
  key_name   = "client3_pub_key"
  public_key = tls_private_key.client3_key.public_key_openssh
}

# Create VPC
resource "aws_vpc" "client3_vpc" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "client3_vpc"
  }
}

# Create Public Subunet 1
resource "aws_subnet" "client3_pub_sn1" {
  vpc_id            = aws_vpc.client3_vpc.id
  cidr_block        = var.pubsub1_cidr
  availability_zone = "eu-west-3a"

  tags = {
    Name = "client3_pub_sn1"
  }
}

# Create Public Subunet 2
resource "aws_subnet" "client3_pub_sn2" {
  vpc_id            = aws_vpc.client3_vpc.id
  cidr_block        = var.pubsub2_cidr
  availability_zone = "eu-west-3b"

  tags = {
    Name = "client3_pub_sn2"
  }
}

# Create Private Subunet 1
resource "aws_subnet" "client3_prv_sn1" {
  vpc_id            = aws_vpc.client3_vpc.id
  cidr_block        = var.prvsub1_cidr
  availability_zone = "eu-west-3a"

  tags = {
    Name = "client3_prv_sn1"
  }
}

# Create Private Subnet 2
resource "aws_subnet" "client3_prv_sn2" {
  vpc_id            = aws_vpc.client3_vpc.id
  cidr_block        = var.prvsub2_cidr
  availability_zone = "eu-west-3b"

  tags = {
    Name = "client3_prv_sn2"
  }
}

# Craete Internet Gateway
resource "aws_internet_gateway" "client3_igw" {
  vpc_id = aws_vpc.client3_vpc.id

  tags = {
    Name = "client3_igw"
  }
}

# Create Elastic IP for NAT Gateway
resource "aws_eip" "client3_nat_eip" {
  vpc = true

  tags = {
    Name = "client3_nat_eip"
  }
}

# Create NAT Gateway
resource "aws_nat_gateway" "client3_ngw" {
  allocation_id = aws_eip.client3_nat_eip.id
  subnet_id     = aws_subnet.client3_pub_sn1.id

  tags = {
    Name = "client3_ngw"
  }
  # Explicit Dependency
  depends_on = [aws_internet_gateway.client3_igw]
}

# Create Route-Table for Public Subnet
resource "aws_route_table" "client3_pub_rt" {
  vpc_id = aws_vpc.client3_vpc.id

  route {
    cidr_block = var.all_ip
    gateway_id = aws_internet_gateway.client3_igw.id
  }
}

# Create Route-Table for Private Subnet
resource "aws_route_table" "client3_prv_rt" {
  vpc_id = aws_vpc.client3_vpc.id

  route {
    cidr_block     = var.all_ip
    nat_gateway_id = aws_nat_gateway.client3_ngw.id
  }
}

# Create Route-Table Association for Public Subnet 1
resource "aws_route_table_association" "client3_pub_sub_rt_as1" {
  subnet_id      = aws_subnet.client3_pub_sn1.id
  route_table_id = aws_route_table.client3_pub_rt.id
}
# Create Route-Table Association for Public Subnet 2
resource "aws_route_table_association" "client3_pub_sub_rt_as2" {
  subnet_id      = aws_subnet.client3_pub_sn2.id
  route_table_id = aws_route_table.client3_pub_rt.id
}

# Create Route-Table Association for Private Subnet 1
resource "aws_route_table_association" "client3_prv_sub_rt_as1" {
  subnet_id      = aws_subnet.client3_prv_sn1.id
  route_table_id = aws_route_table.client3_prv_rt.id
}

# Create Route-Table Association for Private Subnet 2
resource "aws_route_table_association" "client3_prv_sub_rt_as2" {
  subnet_id      = aws_subnet.client3_prv_sn2.id
  route_table_id = aws_route_table.client3_prv_rt.id
}

# Create Ansible Security Group
resource "aws_security_group" "client3_ansible_sg" {
  name        = "PACAEU1-ansible-sg"
  description = "Allow inbound traffic"
  vpc_id      = aws_vpc.client3_vpc.id


  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
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
    Name = "client3_ansible_sg"
  }
}

# Create Sonarqube Security Group
resource "aws_security_group" "client3_sonarqube_sg" {
  name        = "client3_sonarqube_sg"
  description = "Allow inbound traffic"
  vpc_id      = aws_vpc.client3_vpc.id

  ingress {
    description = "sonarqube"
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
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
    Name = "client3_sonarqube_sg"
  }
}

# Create docker security group
resource "aws_security_group" "client3_docker_sg" {
  name        = "client3_docker_sg"
  description = "Allow inbound traffic"
  vpc_id      = aws_vpc.client3_vpc.id


  ingress {
    description = "docker"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.pubsub1_cidr]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.pubsub1_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.all_ip]
  }

  tags = {
    Name = "client3_docker_sg"
  }
}

# Security group for Bastion Host
resource "aws_security_group" "client3_bastion_sg" {
  name        = "client3_bastion_sg"
  description = "Allow traffic for ssh"
  vpc_id      = aws_vpc.client3_vpc.id

  ingress {
    description = "Allow ssh traffic"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.all_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.all_ip]
  }

  tags = {
    Name = "client3_bastion_sg"
  }
}

# Create Jenkins Security Group
resource "aws_security_group" "client3_jenkins_sg" {
  name        = "client3_jenkins_sg"
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
    description = "SSH"
    from_port   = 22
    to_port     = 22
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
    Name = "client3_jenkins_sg"
  }
}



#create ansible server 
resource "aws_instance" "client3_ansible" {
  ami                         = "ami-01daacddaafcdd876"
  instance_type               = "t2.medium"
  subnet_id                   = aws_subnet.client3_pub_sn1.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.client3_ansible_sg.id]
  key_name                    = aws_key_pair.client3_pub_key.key_name
  iam_instance_profile        = aws_iam_instance_profile.client3-IAM-profile.id
  user_data                   = local.ansible_user_data


  tags = {
    Name = "client3_ansible"
  }
}



# Provisioning Bastion Host
resource "aws_instance" "Bastion_host" {
  ami                         = "ami-01daacddaafcdd876"
  instance_type               = "t2.medium"
  key_name                    = aws_key_pair.client3_pub_key.key_name
  subnet_id                   = aws_subnet.client3_pub_sn1.id
  vpc_security_group_ids      = [aws_security_group.client3_bastion_sg.id]
  associate_public_ip_address = true

  user_data = <<-EOF
#!/bin/bash
echo "${tls_private_key.client3_key.private_key_pem}" > /home/ec2-user/client3_prv
sudo chmod 400 client3_prv
sudo hostnamectl set-hostname Bastion
EOF 

  tags = {
    Name = "Bastion_host"
  }
}



#create sonarqube server
resource "aws_instance" "client3_sonarqube" {
  ami                         = "ami-05e8e219ac7e82eba"
  instance_type               = "t2.medium"
  subnet_id                   = aws_subnet.client3_pub_sn1.id
  associate_public_ip_address = true
  vpc_security_group_ids      = ["${aws_security_group.client3_sonarqube_sg.id}"]
  key_name                    = aws_key_pair.client3_pub_key.key_name
  user_data                   = local.sonarqube_user_data


  tags = {
    Name = "client3_sonarqube"
  }
}

# JENKINS SERVER
resource "aws_instance" "client3_Jenkins" {
  ami                         = "ami-01daacddaafcdd876"
  instance_type               = "t2.medium"
  subnet_id                   = aws_subnet.client3_pub_sn1.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.client3_jenkins_sg.id]
  key_name                    = aws_key_pair.client3_pub_key.key_name
  user_data                   = local.jenkins_user_data

  tags = {
    Name = "client3_Jenkins"
  }
}

#IAM instance profile
resource "aws_iam_instance_profile" "client3-IAM-profile" {
  name = "client3-IAM-profile"
  role = aws_iam_role.client3-iam-role.name
}

#IAM role 
resource "aws_iam_role" "client3-iam-role" {
  name        = "client3team1-iam-role"
  description = "ansible autodiscovery"

  assume_role_policy = jsonencode({

    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Effect = "Allow",
        Sid    = ""
      }
    ]
  })
  tags = {
    tag-key = "client3team1-IAM-profile"
  }
}

#IAM role policy 
resource "aws_iam_policy" "client3policy" {
  name        = "test-policy"
  description = "iAM policy"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:Describe*",
        "ec2:DescribeTags*",
        "autoscaling:DescribeTags*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "client3roleattach" {
  role       = aws_iam_role.client3-iam-role.name
  policy_arn = aws_iam_policy.client3policy.arn
}