# main.tf

# This file provisions a simple EC2 instance in an existing AWS VPC using
# reusable, community-maintained AWS Terraform modules.
# It is designed to be as simple as possible while demonstrating
# best practices for modular, clean code.

# ---
# 1. Terraform and Provider Configuration
# ---

terraform {
  required_version = ">= 1.0.0, <= 1.5.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS provider with a default region.
provider "aws" {
  region = "us-east-1"
}

# ---
# 2. Existing VPC Data Source
# ---

# Use a data source to look up an existing VPC by its ID.
# Replace "your-vpc-id" with the actual ID of your VPC.
data "aws_vpc" "existing" {
  id = "your-vpc-id"
}

# We'll use a data source to find a public subnet within the existing VPC.
# This assumes there is at least one public subnet available.
data "aws_subnet" "public" {
  vpc_id = data.aws_vpc.existing.id
  tags = {
    Name = "*public*" # This is a common naming convention for public subnets
  }
}

# ---
# 3. EC2 Instance Module
# ---

# This module provisions a new EC2 instance within the VPC we just created.
# We are using the `terraform-aws-modules/ec2-instance/aws` module.

module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "5.5.0"

  name = "ikurtz-pov-test"

  # Specify the `t2.micro` instance type as requested.
  instance_type = "t2.micro"

  # Get the latest Amazon Linux 2 AMI for a standard, simple setup.
  ami = data.aws_ami.amazon_linux_2.id

  # Connect the instance to the public subnet from our VPC module.
  # The subnet_id is an output from the VPC module.
  subnet_id = data.aws_subnet.public.id

  # Assign a public IP to the instance so we can access it.
  associate_public_ip_address = true

  tags = {
    Owner = "ikurtz"
    Environment = "harness-se"
  }
}

# Find the latest Amazon Linux 2 AMI.
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ---
# 4. Outputs
# ---

# This output provides the public IP address of the EC2 instance,
# making it easy to connect to after provisioning.
output "instance_public_ip" {
  description = "The public IP address of the EC2 instance."
  value       = module.ec2_instance.public_ip
}

# This output provides the public subnet ID where the EC2 instance is located.
output "public_subnet_id" {
  description = "The ID of the public subnet."
  value       = data.aws_subnet.public.id
}
