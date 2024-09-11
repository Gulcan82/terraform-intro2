provider "aws" {
  region = "eu-central-1"
}

# VPC
resource "aws_vpc" "main_vpc_prod" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "main_prod_vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main_igw_prod" {
  vpc_id = aws_vpc.main_vpc_prod.id

  tags = {
    Name = "main_prod_igw"
  }
}

# Public Subnet A
resource "aws_subnet" "main_public_subnet_a_prod" {
  vpc_id                  = aws_vpc.main_vpc_prod.id
  cidr_block              = "10.0.0.0/20"
  availability_zone       = "eu-central-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "main_prod_public_subnet_a"
  }
}

# Private Subnet A
resource "aws_subnet" "main_private_subnet_a_prod" {
  vpc_id            = aws_vpc.main_vpc_prod.id
  cidr_block        = "10.0.128.0/20"
  availability_zone = "eu-central-1a"

  tags = {
    Name = "main_prod_private_subnet_a"
  }
}

# Public Route Table
resource "aws_route_table" "public_rtb_prod" {
  vpc_id = aws_vpc.main_vpc_prod.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw_prod.id
  }

  tags = {
    Name = "main_prod_vpc_public_route_table"
  }
}

# Public Subnet to Public Route Table Association A
resource "aws_route_table_association" "public_rtb_subnet_assoc_prod_a" {
  subnet_id      = aws_subnet.main_public_subnet_a_prod.id
  route_table_id = aws_route_table.public_rtb_prod.id
}

# Public Subnet B
resource "aws_subnet" "main_public_subnet_b_prod" {
  vpc_id                  = aws_vpc.main_vpc_prod.id
  cidr_block              = "10.0.16.0/20"
  availability_zone       = "eu-central-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "main_prod_public_subnet_b"
  }
}

# Private Subnet B
resource "aws_subnet" "main_private_subnet_b_prod" {
  vpc_id            = aws_vpc.main_vpc_prod.id
  cidr_block        = "10.0.144.0/20"
  availability_zone = "eu-central-1b"

  tags = {
    Name = "main_prod_private_subnet_b"
  }
}

# Public Subnet to Public Route Table Association B
resource "aws_route_table_association" "public_rtb_subnet_assoc_prod_b" {
  subnet_id      = aws_subnet.main_public_subnet_b_prod.id
  route_table_id = aws_route_table.public_rtb_prod.id
}

# Security Group
resource "aws_security_group" "web_sg_prod" {
  vpc_id = aws_vpc.main_vpc_prod.id

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
    Name = "web_security_group_prod"
  }
}

# EC2 Instance - Feedback-App Server
resource "aws_instance" "feedback_app_server_prod" {
  ami                    = "ami-0de02246788e4a354"  # Amazon Linux 2 AMI, Region: eu-central-1
  instance_type          = "t2.micro"               # Kostenfreie Instanzgröße, ändere nach Bedarf
  subnet_id              = aws_subnet.main_public_subnet_a_prod.id
  vpc_security_group_ids = [aws_security_group.web_sg_prod.id]

  user_data = <<-EOF
    #!/bin/bash
    # System Update
    yum update -y
    yum install -y docker

    # Start Docker
    service docker start
    systemctl enable docker

    # Docker-Compose installieren
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose

    # Verzeichnis für die App erstellen und die Docker-Compose Datei herunterladen
    mkdir -p /home/ec2-user/feedback-app
    cd /home/ec2-user/feedback-app
    curl -L "https://raw.githubusercontent.com/Gulcan82/feedback-app/main/docker-compose.yml" -o docker-compose.yml

    # Feedback-App starten
    docker-compose up -d
  EOF

  tags = {
    Name = "Feedback-App-Server"
  }
}

# Outputs
output "feedback_app_instance_public_ip" {
  description = "Die öffentliche IP der EC2-Instanz mit der Feedback-App"
  value       = aws_instance.feedback_app_server_prod.public_ip
}
