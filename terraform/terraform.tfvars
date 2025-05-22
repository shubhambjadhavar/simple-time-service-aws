aws_region = "us-east-1"
availability_zones = [
  "us-east-1a",
  "us-east-1b"
]
private_subnets_cidr = [
  "10.8.0.64/27",
  "10.8.0.96/27"
]
public_subnets_cidr = [
  "10.8.0.0/27",
  "10.8.0.32/27"
]
vpc_cidr = "10.8.0.0/24"
ecr_repository_name = "simple-time-service"
image_tag = "latest"