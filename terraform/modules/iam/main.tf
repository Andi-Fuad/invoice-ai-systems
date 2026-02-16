# =====================================================
# IAM Module - Roles and Policies for EC2
# =====================================================

# EC2 Instance Role
resource "aws_iam_role" "ec2" {
  name = "${var.environment}-invoice-ai-ec2-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
  
  tags = {
    Name        = "${var.environment}-invoice-ai-ec2-role"
    Environment = var.environment
  }
}

# Policy for S3 Access
resource "aws_iam_role_policy" "s3_access" {
  name = "${var.environment}-invoice-ai-s3-policy"
  role = aws_iam_role.ec2.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          var.s3_bucket_arn,
          "${var.s3_bucket_arn}/*"
        ]
      }
    ]
  })
}

# Policy for CloudWatch Logs
resource "aws_iam_role_policy" "cloudwatch_logs" {
  name = "${var.environment}-invoice-ai-cloudwatch-policy"
  role = aws_iam_role.ec2.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Policy for CloudWatch Metrics
resource "aws_iam_role_policy" "cloudwatch_metrics" {
  name = "${var.environment}-invoice-ai-metrics-policy"
  role = aws_iam_role.ec2.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics"
        ]
        Resource = "*"
      }
    ]
  })
}

# Policy for ECR (for pulling Docker images)
resource "aws_iam_role_policy" "ecr_access" {
  name = "${var.environment}-invoice-ai-ecr-policy"
  role = aws_iam_role.ec2.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      }
    ]
  })
}

# EC2 Instance Profile
resource "aws_iam_instance_profile" "ec2" {
  name = "${var.environment}-invoice-ai-ec2-profile"
  role = aws_iam_role.ec2.name
  
  tags = {
    Name        = "${var.environment}-invoice-ai-ec2-profile"
    Environment = var.environment
  }
}
