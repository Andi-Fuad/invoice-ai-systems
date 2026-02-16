# =====================================================
# Terraform Variables Configuration
# IMPORTANT: Update these values with your own!
# =====================================================

# AWS Configuration
aws_region  = "ap-southeast-1" 
environment = "dev"
project_name = "invoice-ai"
owner       = "Fuad"  

# Network Configuration
vpc_cidr             = "10.0.0.0/16"
availability_zones   = ["ap-southeast-1a", "ap-southeast-1b"]
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]

# Security Configuration
# IMPORTANT: Replace with your actual IP address!
# Get your IP: curl ifconfig.me
allowed_ssh_cidr = "125.166.19.213/32"  

# EC2 Configuration
instance_type = "t3.micro"  
key_name      = "invoice-ai-key" 

# Database Configuration
db_name     = "invoice_db"
db_username = "invoice_admin"
db_password = "invoice_password_admin"  # CHANGE THIS! Minimum 8 characters

# Application Configuration
gemini_api_key = "AIzaSyCdyhC-kP30UsBSwXg8aU3q_u5q1Y-wPpM" 

# Tags
common_tags = {
  Terraform   = "true"
  CostCenter  = "DevOps-Learning"
  Application = "Invoice-AI-System"
}
