variable "region" {
}

variable "vpc-cidr" {
}

variable "ami" {
}

variable "name" {
}

variable "public_key" {
  default = "~/.ssh/id_rsa.pub"
}

variable "public-subnets" {
}

variable "private-subnets" {
}

variable "create_private_ec2" {
  type    = bool
  default = false
}