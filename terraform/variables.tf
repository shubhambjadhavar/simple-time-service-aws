variable "aws_region" {
  description = "The AWS region where the infrastructure resources will be deployed"
  type        = string
}

variable "availability_zones" {
  description = "List of AWS Availability Zones within the selected region where the resources will be deployed"
  type        = list(string)
  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "You must specify at least 2 availability zones"
  }
}

variable "private_subnets_cidr" {
  description = "List of CIDR blocks for the private subnets within the VPC"
  type        = list(string)
  validation {
    condition     = length(var.private_subnets_cidr) >= 2
    error_message = "You must provide at least 2 private subnet CIDR"
  }
}

variable "public_subnets_cidr" {
  description = "List of CIDR blocks for the public subnets within the VPC"
  type        = list(string)
  validation {
    condition     = length(var.public_subnets_cidr) >= 1
    error_message = "You must provide at least 2 public subnet CIDR"
  }
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
}

variable "image_url" {
  description = "The full URL of the time service container image to be used for deployment"
  type = string
}
