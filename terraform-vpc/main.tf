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

# Public subnet A
resource "aws_subnet" "main_public_subnet_a_prod" {
    vpc_id = aws_vpc.main_vpc_prod.id
    cidr_block = "10.0.0.0/20"
    availability_zone = "eu-central-1a"
    map_public_ip_on_launch = true

    tags = {
        Name = "main_prod_public_subnet_a"
    }
}

# Private subnet
resource "aws_subnet" "main_private_subnet_a_prod" {
    vpc_id = aws_vpc.main_vpc_prod.id
    cidr_block = "10.0.128.0/20"
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

# Public Subnet to Public Route Table Association a
resource "aws_route_table_association" "public_rtb_subnet_assoc_prod_a" {
    subnet_id = aws_subnet.main_public_subnet_a_prod.id
    route_table_id = aws_route_table.public_rtb_prod.id
}

# Public subnet B
resource "aws_subnet" "main_public_subnet_b_prod" {
    vpc_id = aws_vpc.main_vpc_prod.id
    cidr_block = "10.0.16.0/20"
    availability_zone = "eu-central-1b"
    map_public_ip_on_launch = true

    tags = {
        Name = "main_prod_public_subnet_b"
    }
}

# Private subnet B
resource "aws_subnet" "main_private_subnet_b_prod" {
    vpc_id = aws_vpc.main_vpc_prod.id
    cidr_block = "10.0.144.0/20"
    availability_zone = "eu-central-1b"

    tags = {
        Name = "main_prod_private_subnet_b"
    }
}

# Public Subnet to Public Route Table Association B
resource "aws_route_table_association" "public_rtb_subnet_assoc_prod_b" {
    subnet_id = aws_subnet.main_public_subnet_b_prod.id
    route_table_id = aws_route_table.public_rtb_prod.id
}

# Security Group
resource "aws_security_group" "web_sg-prod" {
    vpc_id = aws_vpc.main_vpc_prod.id

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = [ "0.0.0.0/0" ]
    }

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = [ "0.0.0.0/0" ]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = [ "0.0.0.0/0" ]
    }

    tags = {
        Name = "web_security_group_prod"
    }
}

# EC2 Instance - Web Server
resource "aws_instance" "web_server-prod" {
    ami = "ami-0de02246788e4a354"
    instance_type = "t2.micro"
    subnet_id = aws_subnet.main_public_subnet_a_prod.id
    vpc_security_group_ids = [ aws_security_group.web_sg-prod.id ]

    user_data = <<-EOF
    #!/bin/bash
    # Update the system
    dnf update -y

    # Install Node.js and npm
    curl -sL https://rpm.nodesource.com/setup_16.x | bash -
    dnf install -y nodejs git

    # Clone your Express application from GitHub (replace the URL with your repository)
    git clone https://github.com/yourusername/your-express-app.git /home/ec2-user/express-app

    # Change directory to your Express app folder
    cd /home/ec2-user/express-app

    # Install Express app dependencies
    npm install

    # Start the Express application using pm2
    npm install -g pm2
    pm2 start app.js --name "express-app"

    # Enable pm2 to start on system reboot
    pm2 startup systemd
    pm2 save

    echo "Express app started on $(hostname -f)"
    EOF

    tags = {
        Name = "web_server_prod"
    }
}

# Outputs
output "instance_public_ip" {
    description = "The public IP of the EC2 Instance"
    value       = aws_instance.web_server-prod.public_ip
}
