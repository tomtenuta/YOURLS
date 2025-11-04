# VPC Data Sources
# Centralized location for all VPC-related data source queries

# Get existing VPC details
data "aws_vpc" "existing" {
  id = local.vpc_id
}

# Get all subnets in the existing VPC
data "aws_subnets" "existing_all" {
  filter {
    name   = "vpc-id"
    values = [local.vpc_id]
  }
}

# Get subnet details to determine public vs private
data "aws_subnet" "existing_subnet_details" {
  count = length(data.aws_subnets.existing_all.ids)
  id    = data.aws_subnets.existing_all.ids[count.index]
}

# Get route tables for the VPC
data "aws_route_tables" "existing_all" {
  vpc_id = local.vpc_id
}

# Get internet gateway for the VPC
data "aws_internet_gateway" "existing_igw" {
  filter {
    name   = "attachment.vpc-id"
    values = [local.vpc_id]
  }
}

# Get availability zones
data "aws_availability_zones" "available" {}

# Database VPC data sources for peering
data "aws_security_group" "database_sg" {
  id = "sg-e2e313a7"  # nhc-db security group
}

data "aws_vpc" "database_vpc" {
  id = data.aws_security_group.database_sg.vpc_id
}

data "aws_route_tables" "database_vpc_routes" {
  vpc_id = data.aws_vpc.database_vpc.id
} 