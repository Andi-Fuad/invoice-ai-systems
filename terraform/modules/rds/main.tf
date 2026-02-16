# =====================================================
# RDS PostgreSQL Module - FREE TIER Configuration
# =====================================================

# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${var.environment}-invoice-ai-db-subnet"
  subnet_ids = var.private_subnet_ids
  
  tags = {
    Name        = "${var.environment}-invoice-ai-db-subnet-group"
    Environment = var.environment
  }
}

# RDS Instance - FREE TIER COMPATIBLE
resource "aws_db_instance" "main" {
  identifier = "${var.environment}-invoice-ai-db"
  
  # Engine
  engine         = "postgres"
  engine_version = "15.15"
  
  # Instance
  instance_class    = var.instance_class  # db.t3.micro for free tier
  allocated_storage = var.allocated_storage  # 20GB max for free tier
  storage_type      = "gp2"
  storage_encrypted = false  # Free tier doesn't support encryption
  
  # Database
  db_name  = var.db_name
  username = var.db_username
  password = var.db_password
  port     = 5432
  
  # Network
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.db_security_group_id]
  publicly_accessible    = false
  
  # Backup - FREE TIER LIMITS
  backup_retention_period = 0  # Set to 0 for free tier (no automated backups)
  # OR use 1-7 for automated backups (still free tier)
  # backup_retention_period = 1  # Minimum for automated backups
  
  backup_window      = "03:00-04:00"
  maintenance_window = "Mon:04:00-Mon:05:00"
  
  # High Availability
  multi_az = false  # Free tier: single AZ only
  
  # Monitoring - BASIC ONLY FOR FREE TIER
  enabled_cloudwatch_logs_exports = []  # Disabled for free tier
  monitoring_interval            = 0   # 0 = basic monitoring (free)
  
  # Performance Insights
  performance_insights_enabled = false
  
  # Deletion protection
  deletion_protection       = false  # Set to false for easy cleanup
  skip_final_snapshot      = true   # Skip snapshot on deletion
  
  # Auto minor version upgrade
  auto_minor_version_upgrade = true
  
  # Parameter group
  parameter_group_name = aws_db_parameter_group.main.name
  
  tags = {
    Name        = "${var.environment}-invoice-ai-db"
    Environment = var.environment
  }
}

# Custom Parameter Group
resource "aws_db_parameter_group" "main" {
  name   = "${var.environment}-invoice-ai-postgres15"
  family = "postgres15"
  
  parameter {
    name  = "log_connections"
    value = "1"
  }
  
  parameter {
    name  = "log_disconnections"
    value = "1"
  }
  
  tags = {
    Name        = "${var.environment}-invoice-ai-pg"
    Environment = var.environment
  }
}
