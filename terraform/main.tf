# =====================================================
# Invoice AI System - AWS Infrastructure (Free Tier)
# EC2 + Docker Compose Deployment
# =====================================================

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  # Uncomment this after creating S3 bucket for state
  # backend "s3" {
  #   bucket         = "invoice-ai-terraform-state"
  #   key            = "dev/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-state-lock"
  # }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "Invoice-AI-System"
      Environment = var.environment
      ManagedBy   = "Terraform"
      Owner       = var.owner
    }
  }
}

# =====================================================
# VPC Module
# =====================================================
module "vpc" {
  source = "./modules/vpc"
  
  environment         = var.environment
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  public_subnet_cidrs = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

# =====================================================
# Security Groups Module
# =====================================================
module "security" {
  source = "./modules/security"
  
  environment = var.environment
  vpc_id      = module.vpc.vpc_id
  
  # Allow SSH from your IP only
  allowed_ssh_cidr = var.allowed_ssh_cidr
}

# =====================================================
# IAM Roles Module
# =====================================================
module "iam" {
  source = "./modules/iam"
  
  environment = var.environment
  s3_bucket_arn = module.s3.bucket_arn
}

# =====================================================
# S3 Storage Module
# =====================================================
module "s3" {
  source = "./modules/s3"
  
  environment = var.environment
  bucket_name = "${var.project_name}-invoices-${var.environment}"
}

# =====================================================
# RDS PostgreSQL Module
# =====================================================
module "rds" {
  source = "./modules/rds"
  
  environment             = var.environment
  vpc_id                 = module.vpc.vpc_id
  private_subnet_ids     = module.vpc.private_subnet_ids
  db_security_group_id   = module.security.db_security_group_id
  
  db_name                = var.db_name
  db_username            = var.db_username
  db_password            = var.db_password
  
  # Free tier settings
  instance_class         = "db.t3.micro"  # Free tier eligible
  allocated_storage      = 20              # Free tier: up to 20GB
  backup_retention_period = 7
  multi_az              = false            # Free tier: single AZ only
}

# =====================================================
# EC2 Instance Module
# =====================================================
module "ec2" {
  source = "./modules/ec2"
  
  environment           = var.environment
  vpc_id               = module.vpc.vpc_id
  public_subnet_id     = module.vpc.public_subnet_ids[0]
  
  instance_type        = var.instance_type  # t3.micro for free tier
  key_name             = var.key_name
  
  ec2_security_group_id = module.security.ec2_security_group_id
  iam_instance_profile  = module.iam.ec2_instance_profile_name
  
  # Application configuration
  db_host              = module.rds.db_endpoint
  db_name              = var.db_name
  db_username          = var.db_username
  db_password          = var.db_password
  gemini_api_key       = var.gemini_api_key
  s3_bucket_name       = module.s3.bucket_name
  
  depends_on = [
    module.rds,
    module.s3
  ]
}

# =====================================================
# Outputs
# =====================================================
output "application_url" {
  description = "URL to access the application"
  value       = "http://${module.ec2.public_ip}"
}

output "ssh_command" {
  description = "Command to SSH into the EC2 instance"
  value       = "ssh -i ${var.key_name}.pem ec2-user@${module.ec2.public_ip}"
}

output "database_endpoint" {
  description = "RDS database endpoint"
  value       = module.rds.db_endpoint
  sensitive   = true
}

output "s3_bucket_name" {
  description = "S3 bucket for invoice storage"
  value       = module.s3.bucket_name
}

output "ec2_instance_id" {
  description = "EC2 instance ID"
  value       = module.ec2.instance_id
}

output "streamlit_url" {
  description = "Streamlit application URL"
  value       = "http://${module.ec2.public_ip}:8501"
}

output "fastapi_docs_url" {
  description = "FastAPI documentation URL"
  value       = "http://${module.ec2.public_ip}:8000/docs"
}
