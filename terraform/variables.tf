// variables.tf
variable "aws_region" {
  description = "AWS region to deploy the infrastructure in"
  type        = string
  default     = "us-west-2"            # default to Oregon; can be overridden via ENV or tfvars
}

variable "vpc_id" {
  description = "ID of the existing VPC to use for the EC2 instance"
  type        = string
}

variable "subnet_id" {
  description = "ID of an existing subnet (in the VPC) for the EC2 instance"
  type        = string
}

variable "key_name" {
  description = "Name of an existing EC2 Key Pair for SSH access"
  type        = string
}

variable "instance_name" {
  description = "Name tag for the EC2 instance"
  type        = string
  default     = "terraform-ec2-demo"
}

variable "instance_type" {
  description = "EC2 instance type to use"
  type        = string
  default     = "m7g.xlarge"            # m7g.xlarge ARM64 Graviton3: 4 vCPUs, 16GB RAM
}

variable "alert_email" {
  description = "Email address to receive CloudWatch alarm notifications"
  type        = string
  default     = "orlando@aloware.com"
}

variable "cpu_threshold" {
  description = "CPU utilization percentage threshold for CloudWatch alarm"
  type        = number
  default     = 25
}
