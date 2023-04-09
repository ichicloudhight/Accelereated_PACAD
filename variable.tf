# VPC CIDR 
variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

#Public Subnet 1 CIDR
variable "pubsub1_cidr" {
  default = "10.0.1.0/24"
}

#Public Subnet 2 CIDR
variable "pubsub2_cidr" {
  default = "10.0.2.0/24"
}

#Private Subnet 1 CIDR
variable "prvsub1_cidr" {
  default = "10.0.3.0/24"
}

#Private Subnet 2 CIDR
variable "prvsub2_cidr" {
  default = "10.0.4.0/24"
}

#All IP CIDR
variable "all_ip" {
  default = "0.0.0.0/0"
}

