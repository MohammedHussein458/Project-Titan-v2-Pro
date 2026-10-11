terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Create VPC 
resource "aws_vpc" "titan_vpc" {
  cidr_block =  "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name ="titan-pro-vpc"
  }
}


# Create Internet Gateway
resource "aws_internet_gateway" "titan_igw" {
  vpc_id = aws_vpc.titan_vpc.id

  tags = {
    Name ="titan-pro-igw"
  }
}

# Create Public Subnet
resource "aws_subnet" "public_subnet_1" {
  vpc_id = aws_vpc.titan_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "titan-public-subnet-1"
  }  
}

# Create Private Subnet
resource "aws_subnet" "private_subnet_1" {
  vpc_id = aws_vpc.titan_vpc.id
  cidr_block =  "10.0.10.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "titan-private-subnet-1a"
  }
}


# Create Route Table 
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.titan_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.titan_igw.id
  }

  tags = {
    Name = "titan-pro-public-rt"
  }
}

# Create Route Table Association 
resource "aws_route_table_association" "rt_association" {
  subnet_id = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_rt.id
}

# Create Security Group
resource "aws_security_group" "titan-sg" {
  name = "titan-automated-sg"
  description = "Allow HTTP and SSH"
  vpc_id = aws_vpc.titan_vpc.id

  #Allow HTTP from all of the internet
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



  #Allow to leave internet (Outbound)
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "titan-sg"
  }
}

# Creat EC2 Instance
resource "aws_instance" "titan_web" {
  ami           = "ami-04a81a99f5ec58529"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_subnet_1.id
  vpc_security_group_ids = [aws_security_group.titan-sg.id]

    user_data = <<-EOF
                #!/bin/bash
                dnf update -y
                dnf install -y httpd
                systemctl start httpd
                systemctl enable httpd
                echo "<h1>Project Titan v2 Pro - ALB Working! 🚀</h1>" > /var/www/html/index.html
                EOF

  tags = {
    Name = "titan-automated-server"
  }             
}

output "web_server_ip" {
  value       = aws_instance.titan_web.public_ip
  description = "Public IP address of the web server"
}

# Create Elastic IP
resource "aws_eip" "nat_eip" {
  domain = "vpc"
  tags = {
    Name = "titan-nat-eip"
  }
}

# Create NAT Gateway
resource "aws_nat_gateway" "titan_nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id = aws_subnet.public_subnet_1.id

  tags = {
    Name = "titan-pro-nat-gw"
  }
  depends_on = [ aws_internet_gateway.titan_igw]
}

# Create Private Route Table
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.titan_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.titan_nat.id
  }

  tags = {
    Name = "titan-pro-private-rt"
  }
}

# Create Route Table Association
resource "aws_route_table_association" "private-assoc" {
  subnet_id = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_rt.id
}


# Create Target Group
resource "aws_lb_target_group" "titan_tg" {
  name = "titan-pro-tg"
  port = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.titan_vpc.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    port                = "80"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# Create Public Subnet 2
resource "aws_subnet" "public_subnet_2" {
  vpc_id = aws_vpc.titan_vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "titan-public-subnet-2"
  }
}

# Create Route Table Association
resource "aws_route_table_association" "public_assoc_2" {
  subnet_id = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_rt.id
}

# Create Application Load Balancer
resource "aws_lb" "titan_alb" {
  name               = "titan-pro-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.titan-sg.id]
  subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]

  tags = {
    Name = "titan-pro-alb"
  }
}

# Create Listener for ALB
resource "aws_lb_listener" "titan_listener" {
  load_balancer_arn = aws_lb.titan_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.titan_tg.arn
  }
}

resource "aws_lb_target_group_attachment" "titan_attach" {
  target_group_arn = aws_lb_target_group.titan_tg.arn
  target_id        = aws_instance.titan_web.id
  port             = 80
}

output "alb_dns_name" {
  value       = aws_lb.titan_alb.dns_name
  description = "The DNS name of the Application Load Balancer"
}