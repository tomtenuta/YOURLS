# VPC Peering for Database Access
# Shared resource across all environments

# Import existing VPC peering connection
# This resource is shared across all environments - import it once per environment:
# terraform import aws_vpc_peering_connection.database_peering pcx-002b0db02d1f4b2da
resource "aws_vpc_peering_connection" "database_peering" {
  count      = 0  # managed outside this stack to avoid conflicts
  peer_vpc_id = data.aws_vpc.database_vpc.id
  vpc_id      = data.aws_vpc.existing.id
  auto_accept = true
}

# NOTE: Shared infrastructure is managed outside of environment-specific Terraform
# 
# The following resources are pre-existing and shared across all environments:
# 1. Routes between the centralized VPC and database VPC
# 2. Security group rules for database access
#
# Managing these in environment-specific Terraform states causes conflicts
# during parallel deployments. These should be managed in a separate
# shared infrastructure configuration or created manually once.
#
# To manually verify routes exist:
# aws ec2 describe-route-tables --filters "Name=vpc-id,Values=vpc-0c23f21054cebe40e" --query 'RouteTables[*].Routes[?DestinationCidrBlock==`172.31.0.0/16`]'
# aws ec2 describe-route-tables --filters "Name=vpc-id,Values=vpc-fab50780" --query 'RouteTables[*].Routes[?DestinationCidrBlock==`10.0.0.0/16`]'
#
# To manually create routes if needed:
# aws ec2 create-route --route-table-id <rtb-id> --destination-cidr-block 172.31.0.0/16 --vpc-peering-connection-id pcx-0af19dadb0a46f226
# aws ec2 create-route --route-table-id <rtb-id> --destination-cidr-block 10.0.0.0/16 --vpc-peering-connection-id pcx-0af19dadb0a46f226

# Security group rules are also pre-existing shared infrastructure
# To verify security group rule exists:
# aws ec2 describe-security-groups --group-ids sg-e2e313a7 --query 'SecurityGroups[0].IpPermissions[?FromPort==`3306`]' 