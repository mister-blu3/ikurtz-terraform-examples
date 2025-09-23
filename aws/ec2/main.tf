//Define the provider and any data sources
provider "aws" {
  region = "us-east-1"
}

// AWS VPC
data "aws_vpc" "selected" {
  id = var.vpc_id
}

// AWS Subnet
data "aws_subnet" "selected" {
  id = var.subnet_id
}
