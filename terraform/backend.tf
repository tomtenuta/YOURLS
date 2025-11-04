terraform {
  required_version = ">= 1.3"

  backend "s3" {
    # Isolated state for YOURLS project
    bucket         = "autom8-terraform-state"
    key            = "yourls/prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
