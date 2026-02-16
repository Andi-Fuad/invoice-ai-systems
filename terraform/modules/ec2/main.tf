# =====================================================
# EC2 Module - Application Server
# =====================================================

# Latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
  
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Current AWS region
data "aws_region" "current" {}

# EC2 Instance
resource "aws_instance" "main" {
  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = var.instance_type
  key_name      = var.key_name
  
  subnet_id                   = var.public_subnet_id
  vpc_security_group_ids      = [var.ec2_security_group_id]
  iam_instance_profile        = var.iam_instance_profile
  associate_public_ip_address = true
  
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 30  
    encrypted             = true
    delete_on_termination = true
    
    tags = {
      Name        = "${var.environment}-invoice-ai-root-volume"
      Environment = var.environment
    }
  }
  
  user_data = templatefile("${path.module}/user-data.sh", {
    db_name        = var.db_name
    db_username    = var.db_username
    db_password    = var.db_password
    db_host        = var.db_host
    gemini_api_key = var.gemini_api_key
    aws_region     = data.aws_region.current.name
    s3_bucket_name = var.s3_bucket_name
  })
  
  user_data_replace_on_change = true
  
  tags = {
    Name        = "${var.environment}-invoice-ai-ec2"
    Environment = var.environment
    Role        = "Application-Server"
  }
  
  lifecycle {
    ignore_changes = [ami]
  }
}

# Elastic IP (optional but recommended for consistent access)
resource "aws_eip" "main" {
  instance = aws_instance.main.id
  domain   = "vpc"
  
  tags = {
    Name        = "${var.environment}-invoice-ai-eip"
    Environment = var.environment
  }
  
  depends_on = [aws_instance.main]
}
