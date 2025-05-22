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
image_url = "public.ecr.aws/x4u4h4k5/demo/simple-time-service:latest"