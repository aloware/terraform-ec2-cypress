// main.tf
provider "aws" {
  region = var.aws_region
}

// Lookup latest Ubuntu 22.04 LTS AMI ID via AWS SSM Parameter Store (region-specific)
data "aws_ssm_parameter" "ubuntu_ami" {
  name = "/aws/service/canonical/ubuntu/server/22.04/stable/current/amd64/hvm/ebs-gp2/ami-id"
}

// Security Group to allow SSH (22) and HTTP (80)
resource "aws_security_group" "instance_sg" {
  name        = "${var.instance_name}-sg"
  description = "Security group for EC2 allowing SSH and HTTP"
  vpc_id      = var.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]    # SSH open to all (for demo). Restrict in real use!
  }
  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]    # HTTP open to all (for web testing)
  }
  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]    # Allow all egress
  }

  tags = {
    Name = "${var.instance_name}-sg"
  }
}

// EC2 Instance resource
resource "aws_instance" "ubuntu_server" {
  ami                    = data.aws_ssm_parameter.ubuntu_ami.value
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id            # Launch in this existing subnet
  vpc_security_group_ids = [aws_security_group.instance_sg.id]
  key_name               = var.key_name             # Use existing Key Pair for SSH access

  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update -y
              sudo apt-get install -y nginx
              sudo systemctl enable nginx
              sudo systemctl start nginx
              EOF

  tags = {
    Name = var.instance_name
  }
}

// Allocate Elastic IP (needed if subnet doesn't auto-assign public IPs)
resource "aws_eip" "instance_eip" {
  instance = aws_instance.ubuntu_server.id
  domain   = "vpc"

  tags = {
    Name = "${var.instance_name}-eip"
  }
}

// Output the instance's public IP for use in pipeline
output "public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_eip.instance_eip.public_ip
}

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.ubuntu_server.id
}
