# VPC
# Create a VPC with only a public subnet

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "1.53.0"

  name            = "vpc-jbrt"
  cidr            = "10.0.0.0/16"
  azs             = "${var.availability_zones}"
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets = ["10.0.10.0/24", "10.0.20.0/24", "10.0.30.0/24"]

  enable_dns_support   = true
  enable_dns_hostnames = true
  enable_nat_gateway   = true
  single_nat_gateway   = true

  tags                = "${local.tags}"
}
