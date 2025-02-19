resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc-cidr
  enable_dns_hostnames = true
  tags = {
    Name = "${var.name}-vpc"
  }
}
resource "aws_subnet" "public_subnet" {
  count = 3
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = cidrsubnet(var.vpc-cidr, 8, count.index)
  map_public_ip_on_launch = true
  availability_zone = "${var.region}${element(["a", "b", "c"], count.index)}"
  tags = {
    Name = "${var.name}-public-subnet-${element(["a", "b", "c"], count.index)}"
  }
}
resource "aws_subnet" "private_subnet" {
  count = 3
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = cidrsubnet(var.vpc-cidr, 8, count.index + 10)
  availability_zone = "${var.region}${element(["a", "b", "c"], count.index)}"
  tags = {
    Name = "${var.name}-private-subnet-${element(["a", "b", "c"], count.index)}"
  }

}
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${var.name}-route-table"
  }
}
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${var.name}-internet-gateway"
  }

}
resource "aws_route" "public_subnet_route" {
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
  route_table_id         = aws_route_table.public_route_table.id
}
resource "aws_route_table_association" "public_assoc" {
  count = 3
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public_route_table.id
}
resource "aws_key_pair" "public_ssh" {
  public_key = file(pathexpand(var.public_key))
}
resource "aws_instance" "web_ec2" {
  ami                         = var.ami
  instance_type               = "t4g.small"
  vpc_security_group_ids      = [aws_security_group.web_instance_sg.id]
  subnet_id     = element(aws_subnet.public_subnet[*].id, random_integer.subnet_index.result)
  associate_public_ip_address = true
  key_name                    = aws_key_pair.public_ssh.key_name
  user_data                   = <<EOF
#!/bin/sh
sudo apt install -y nginx
sudo systemctl enable nginx.service
sudo systemctl start nginx.service
sudo apt update
sudo apt upgrade -y
sudo reboot
EOF

  tags = {
    Name = "${var.name}-web-ec2"
  }

}
resource "random_integer" "subnet_index" {
  min = 0
  max = 2
}
resource "aws_security_group" "web_instance_sg" {
  vpc_id = aws_vpc.vpc.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
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
}

