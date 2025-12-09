// main.tf
provider "aws" {
  region = var.aws_region
}

// Lookup latest Ubuntu 22.04 LTS AMI ID via AWS SSM Parameter Store (region-specific)
// Using ARM64 for Graviton3 instances (m7g family)
data "aws_ssm_parameter" "ubuntu_ami" {
  name = "/aws/service/canonical/ubuntu/server/22.04/stable/current/arm64/hvm/ebs-gp2/ami-id"
}

// IAM Role for Session Manager access
resource "aws_iam_role" "ssm_role" {
  name = "${var.instance_name}-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = {
    Name = "${var.instance_name}-ssm-role"
  }
}

// Attach AWS managed policy for Session Manager
resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

// Instance profile to attach role to EC2
resource "aws_iam_instance_profile" "ssm_profile" {
  name = "${var.instance_name}-ssm-profile"
  role = aws_iam_role.ssm_role.name
}

// Attach Session Manager user policy to Developers group
resource "aws_iam_group_policy_attachment" "developers_ssm" {
  group      = "Developers"
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
}

// Security Group - HTTP only, SSH disabled (use Session Manager for access)
resource "aws_security_group" "instance_sg" {
  name        = "${var.instance_name}-sg"
  description = "Security group for EC2 allowing SSH and HTTP"
  vpc_id      = var.vpc_id

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
  iam_instance_profile   = aws_iam_instance_profile.ssm_profile.name

  root_block_device {
    volume_size           = 50
    volume_type           = "gp3"
    iops                  = 3000
    throughput            = 125
    delete_on_termination = true
  }

  user_data = <<-EOF
              #!/bin/bash
              set -e
              
              # Update system
              sudo apt-get update -y
              
              # Install Nginx
              sudo apt-get install -y nginx
              sudo systemctl enable nginx
              sudo systemctl start nginx
              
              # Install Docker
              sudo apt-get install -y ca-certificates curl
              sudo install -m 0755 -d /etc/apt/keyrings
              sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
              sudo chmod a+r /etc/apt/keyrings/docker.asc
              echo "deb [arch=arm64 signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
              sudo apt-get update -y
              sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
              sudo systemctl enable docker
              sudo systemctl start docker
              sudo usermod -aG docker ubuntu
              
              # Install Cypress system dependencies
              sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
                libgtk2.0-0 libgtk-3-0 libgbm-dev libnotify-dev \
                libnss3 libxss1 libasound2 libxtst6 xauth xvfb
              
              # Install Node.js 18.x
              curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
              sudo apt-get install -y nodejs
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
