# =====================================================
# Core Variables
# =====================================================

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "invoice-ai"
}

variable "owner" {
  description = "Owner tag for resources"
  type        = string
  default     = "DevOps-Portfolio"
}

# =====================================================
# Network Variables
# =====================================================

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH into EC2 instance"
  type        = string
  default     = "0.0.0.0/0"  # CHANGE THIS to your IP for security!
  
  # Example: "1.2.3.4/32" for your specific IP
  # Get your IP: curl ifconfig.me
}

# =====================================================
# EC2 Variables
# =====================================================

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"  # Free tier eligible
}

variable "key_name" {
  description = "EC2 key pair name (must be created in AWS first)"
  type        = string
  
  # You need to create this in AWS Console:
  # EC2 > Key Pairs > Create key pair
  # Example: "invoice-ai-system-key"
}

# =====================================================
# Database Variables
# =====================================================

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "invoice_admin"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "invoice_admin"
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
  
  # Set this via environment variable or terraform.tfvars
  # Must be at least 8 characters
}

# =====================================================
# Application Variables
# =====================================================

variable "gemini_api_key" {
  description = "Google Gemini API key"
  type        = string
  sensitive   = true
  
  # Set this via environment variable or terraform.tfvars
  # Get from: https://makersuite.google.com/app/apikey
}

# =====================================================
# Tags
# =====================================================

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Terraform   = "true"
    CostCenter  = "DevOps-Learning"
    Application = "Invoice-AI-System"
  }
}
