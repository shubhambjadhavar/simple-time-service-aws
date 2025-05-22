module "vpc" {
  source                        = "terraform-aws-modules/vpc/aws"
  version                       = "5.0.0"
  name                          = "simple-time-service-vpc"
  azs                           = var.availability_zones
  cidr                          = var.vpc_cidr
  enable_dns_hostnames          = true
  enable_nat_gateway            = true
  map_public_ip_on_launch       = false
  manage_default_network_acl    = false
  manage_default_route_table    = false
  manage_default_security_group = false
  public_subnets                = var.public_subnets_cidr
  private_subnets               = var.private_subnets_cidr
  single_nat_gateway            = true
}

module "simple-time-service-alb-security-group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.0"

  name   = "application-loadbalancer-ec2-security-group"
  vpc_id = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      rule        = "http-80-tcp"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  egress_with_cidr_blocks = [
    {
      rule        = "all-all"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
}

module "simple-time-service-alb" {
  source = "terraform-aws-modules/alb/aws"
  version = "9.16.0"

  name    = "simple-time-service-alb"
  vpc_id  = module.vpc.vpc_id
  subnets = module.vpc.public_subnets
  create_security_group = false
  security_groups = [
    module.simple-time-service-alb-security-group.security_group_id
  ]

  listeners = {
    http = {
      port       = 80
      protocol   = "HTTP"
      forward = {
        target_group_key = "simple-time-service-ecs"
      }
    }
  }

  target_groups = {
    simple-time-service-ecs = {
      protocol                          = "HTTP"
      port                              = 8080
      target_type                       = "ip"
      deregistration_delay              = 10
      load_balancing_cross_zone_enabled = true

      health_check = {
        enabled             = true
        interval            = 5
        path                = "/health"
        port                = "8080"
        healthy_threshold   = 2
        unhealthy_threshold = 2
        timeout             = 2
        protocol            = "HTTP"
        matcher             = "200-299"
      }
      create_attachment = false
    }
  }
}

module "simple-time-service-ecs-task-security-group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.0"

  name   = "simple-time-service-ecs-ec2-security-group"
  vpc_id = module.vpc.vpc_id

  ingress_with_source_security_group_id = [
    {
      rule        = "http-8080-tcp"
      source_security_group_id = module.simple-time-service-alb-security-group.security_group_id
    }
  ]

  egress_with_cidr_blocks = [
    {
      rule        = "all-all"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
}

data "aws_caller_identity" "current" {}

module "simple-time-service-ecs" {
  source = "terraform-aws-modules/ecs/aws"
  version = "5.12.1"
  cluster_name = "simple-time-service-ecs-cluster"
  services = {
    simple-time-service = {
      # Service
      assign_public_ip = false
      deployment_maximum_percent = 200
      deployment_minimum_healthy_percent = 100
      desired_count = 1
      enable_execute_command = true
      health_check_grace_period_seconds = 30
      launch_type = "FARGATE"
      load_balancer = {}
      propagate_tags = "SERVICE"
      create_security_group = false
      security_group_ids = [
        module.simple-time-service-ecs-task-security-group.security_group_id
      ]
      scheduling_strategy = "REPLICA"
      subnet_ids = module.vpc.private_subnets
      wait_for_steady_state = true

      # Task definition
      cpu    = 256
      memory = 512
      network_mode = "awsvpc"
      requires_compatibilities = [
        "FARGATE"
      ]
      runtime_platform = {
        operating_system_family = "LINUX"
        cpu_architecture        = "X86_64"
      }
      container_definitions = {
        simple-time-service-container = {
          essential = true
          image     = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.ecr_repository_name}:${var.image_tag}"
          port_mappings = [
            {
              name          = "simple-time-service"
              containerPort = 8080
              protocol      = "tcp"
            }
          ]
          readonly_root_filesystem = true
          enable_cloudwatch_logging = false
          memory_reservation = 256
        }
      }

      load_balancer = {
        service = {
          target_group_arn = module.simple-time-service-alb.target_groups["simple-time-service-ecs"].arn
          container_name   = "simple-time-service-container"
          container_port   = 8080
        }
      }

      # Autoscaling
      enable_autoscaling = false
    }
  }
}

output "web-service-url-root" {
  value = "http://${module.simple-time-service-alb.dns_name}/"
}

output "web-service-url-health" {
  value = "http://${module.simple-time-service-alb.dns_name}/health"
}