terraform {
  cloud {
    organization = "training-aws"

    workspaces {
      name = "vpc"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }
}

provider "aws" {
  profile = "default"
  region  = "us-west-2"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

resource "aws_vpc" "my-vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "my-vpc"
  }
}

resource "aws_subnet" "my-public-subnet" {
  vpc_id = aws_vpc.my-vpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "my-public-subnet"
  }
}

resource "aws_internet_gateway" "my-internet-gateway" {
  vpc_id = aws_vpc.my-vpc.id

  tags = {
    Name = "my-internet-gateway"
  }
}

resource "aws_route_table" "my-public-route-table" {
  vpc_id = aws_vpc.my-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my-internet-gateway.id
  }

  tags = {
    Name = "my-public-route-table"
  }
}

resource "aws_subnet" "my-private-subnet" {
  vpc_id = aws_vpc.my-vpc.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "my-private-subnet"
  }
}

resource "aws_route_table" "my-private-route-table" {
  vpc_id = aws_vpc.my-vpc.id

  tags = {
    Name = "my-private-route-table"
  }
}

resource "aws_route_table_association" "public_association" {
  subnet_id = aws_subnet.my-public-subnet.id
  route_table_id = aws_route_table.my-public-route-table.id
}

resource "aws_route_table_association" "pivate_association" {
  subnet_id = aws_subnet.my-private-subnet.id
  route_table_id = aws_route_table.my-private-route-table.id
}

resource "tls_private_key" "private_key" {
  algorithm = "RSA"
  rsa_bits = 4096
}

resource "aws_key_pair" "my-ec2-keypair" {
  key_name = "remote-connect"
  public_key = tls_private_key.private_key.public_key_openssh

  tags = {
    Name = "my-ec2-keypair"
  }
}

resource "aws_security_group" "ec2-sg" {
  vpc_id = aws_vpc.my-vpc.id
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "myec2-public-instance" {
  subnet_id = aws_subnet.my-public-subnet.id
  count = 1
  ami = "ami-04e35eeae7a7c5883"
  instance_type = "t2.micro"
  key_name = aws_key_pair.my-ec2-keypair.key_name
  associate_public_ip_address = true
  security_groups = [aws_security_group.ec2-sg.id]

  tags = {
    Name = "myec2-public-instance"
  }
}


resource "aws_instance" "myec2-private-instance" {
  subnet_id = aws_subnet.my-private-subnet.id
  count = 1
  ami = "ami-04e35eeae7a7c5883"
  instance_type = "t2.micro"
  key_name = aws_key_pair.my-ec2-keypair.key_name
  security_groups = [aws_security_group.ec2-sg.id]

  tags = {
    Name = "myec2-private-instance"
  }
}