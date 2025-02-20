data "aws_availability_zones" "available" {}

resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc-cidr
  enable_dns_hostnames = true
  tags = {
    Name = "${var.name}-vpc"
  }
}

resource "aws_subnet" "public_subnet" {
  count                   = var.public-subnets
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = cidrsubnet(var.vpc-cidr, 7, count.index)
  map_public_ip_on_launch = true
  availability_zone       = element(data.aws_availability_zones.available.names, count.index)
  tags = {
    Name = "${var.name}-public-subnet-${element(data.aws_availability_zones.available.names, count.index)}"
  }
}

resource "aws_subnet" "private_subnet" {
  count             = var.private-subnets
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = cidrsubnet(var.vpc-cidr, 6, count.index + 10)
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
  tags = {
    Name = "${var.name}-private-subnet-${element(data.aws_availability_zones.available.names, count.index)}"
  }

}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${var.name}-public-route-table"
  }
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${var.name}-private-route-table"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${var.name}-internet-gateway"
  }
}

resource "aws_eip" "nat_ip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_ip.id
  subnet_id     = aws_subnet.public_subnet[0].id
  tags = {
    Name = "${var.name}-nat-gateway"
  }
}

resource "aws_route" "private_route_table" {
  route_table_id         = aws_route_table.private_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gw.id
}

resource "aws_route" "public_subnet_route" {
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
  route_table_id         = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_assoc" {
  count          = var.public-subnets
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "private_assoc" {
  count          = var.public-subnets
  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_key_pair" "public_ssh" {
  public_key = file(pathexpand(var.public_key))
}

resource "aws_instance" "public_ec2" {
  ami                         = var.ami
  instance_type               = "t4g.small"
  vpc_security_group_ids      = [aws_security_group.public_sg.id]
  subnet_id                   = element(aws_subnet.public_subnet[*].id, random_integer.subnet_index.result)
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
  lifecycle {
    ignore_changes = [subnet_id]
  }
  tags = {
    Name = "${var.name}-public-ec2"
  }
}

resource "random_integer" "subnet_index" {
  min = 0
  max = 2
}

resource "aws_security_group" "public_sg" {
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
  tags = {
    Name = "${var.name}-public-sg"
  }
}

resource "aws_security_group" "private_sg" {
  vpc_id = aws_vpc.vpc.id
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.public_sg.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.name}-private-sg"
  }
}

resource "aws_instance" "private_ec2" {
  count                       = var.create_private_ec2 ? 1 : 0
  ami                         = var.ami
  instance_type               = "t4g.small"
  vpc_security_group_ids      = [aws_security_group.private_sg.id]
  subnet_id                   = element(aws_subnet.private_subnet[*].id, random_integer.subnet_index.result)
  associate_public_ip_address = true
  key_name                    = aws_key_pair.public_ssh.key_name

  lifecycle {
    ignore_changes = [subnet_id]
  }
  tags = {
    Name = "${var.name}-private-ec2"
  }
}