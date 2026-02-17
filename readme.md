# Invoice AI System

AI-powered invoice processing system with automated data extraction and cloud deployment on AWS.

## Overview

The Invoice AI System is a full-stack application that automates invoice processing using Google's Gemini Vision API. It features a FastAPI backend, Streamlit frontend, and complete AWS infrastructure managed through Terraform.

There are three types of branches in this repository:
- **Main**: Serves as the official, live version of the project.
- **Staging**: Acts as a mirror of the production environment for final testing. It provides a "safety net" to catch bugs that only appear in a production-like setting.
- **Development Branches**: Serves as the developments and researches for the project.

## Features

- **AI-Powered Extraction**: Automatic extraction of vendor names, amounts, dates, and line items from invoice images
- **Multiple File Formats**: Support for PNG, JPEG, and WEBP invoices
- **Intelligent Caching**: File hash-based duplicate detection to reduce API costs
- **Report Generation**: Automated PDF report creation with customizable filters (Under Development)
- **Cloud Storage**: S3 integration for invoice storage with lifecycle policies
- **RESTful API**: Complete FastAPI backend with interactive documentation
- **Modern UI**: Streamlit-based interface with real-time processing status
- **Infrastructure as Code**: Terraform modules for reproducible AWS deployments

## Technology Stack

### Application
- **Backend**: FastAPI, SQLAlchemy, PostgreSQL
- **Frontend**: Streamlit
- **AI/ML**: Google Gemini Vision API
- **File Processing**: Pillow, python-multipart

### Infrastructure
- **Cloud Provider**: AWS
- **Compute**: EC2 t3.micro
- **Database**: RDS PostgreSQL t3.micro
- **Storage**: S3
- **IaC**: Terraform 1.0+
- **Containers**: Docker, Docker Compose

### DevOps
- **CI/CD**: GitHub Actions (Under Development)
- **Monitoring**: AWS CloudWatch (Under Development)
- **Version Control**: Git

## Architecture

```
┌─────────────────┐
│   Streamlit UI  │
└────────┬────────┘
         │
    ┌────▼─────┐
    │  FastAPI │
    └────┬─────┘
         │
    ┌────┴────┬──────────┐
    │         │          │
┌───▼───┐ ┌──▼───┐  ┌───▼────┐
│  RDS  │ │  S3  │  │ Gemini │
└───────┘ └──────┘  └────────┘
```

## Prerequisites

### Local Development
- Docker and Docker Compose
- Python 3.11+
- PostgreSQL 15 (via Docker)

### AWS Deployment
- AWS Account with Free Tier
- Terraform 1.0+
- AWS CLI configured
- SSH key pair in AWS
- Gemini API key

## Quick Start

### Project's Public IP: http://18.138.190.182:8501/ (Check it out)

### Local Development

1. Clone the repository:
```bash
git clone https://github.com/andifuad104/invoice-ai-system.git
cd invoice-ai-system
```

2. Create environment file:
```bash
cp .env
```

3. Start services:
```bash
docker-compose up -d
```

4. Access the application:
- Streamlit UI: http://localhost:8501
- FastAPI Docs: http://localhost:8000/docs
- FastAPI Health: http://localhost:8000/health

### AWS Deployment

1. Navigate to Terraform directory:
```bash
cd terraform
```

2. Configure variables:
```bash
cp terraform.tfvars.example terraform.tfvars
```

3. Initialize and deploy:
```bash
terraform init
terraform plan
terraform apply
```

4. Access outputs:
```bash
terraform output
```

## Project Structure

```
invoice-ai-system/
├── app/                      # FastAPI backend
│   ├── main.py              # Application entry point
│   ├── config.py            # Configuration management
│   ├── database.py          # Database connection
│   ├── models/              # SQLAlchemy models
│   ├── routers/             # API endpoints
│   ├── schemas/             # Pydantic schemas
│   ├── services/            # Business logic
│   └── utils/               # Helper functions
├── streamlit_app/           # Streamlit frontend
│   ├── Home.py              # Main dashboard
│   └── pages/               # Additional pages
├── terraform/               # Infrastructure as Code
│   ├── main.tf              # Root module
│   ├── variables.tf         # Variable definitions
│   ├── outputs.tf           # Output values
│   └── modules/             # Reusable modules
│       ├── vpc/             # Network infrastructure
│       ├── ec2/             # Application server
│       ├── rds/             # Database
│       ├── s3/              # Storage
│       ├── iam/             # Roles and policies
│       └── security/        # Security groups
├── docker-compose.yml       # Local development
├── Dockerfile.api           # FastAPI container
├── Dockerfile.streamlit     # Streamlit container
└── requirements.txt         # Python dependencies
```

## API Endpoints

### Invoices
- `POST /invoices/upload` - Upload and process invoice
- `GET /invoices/` - List all invoices
- `GET /invoices/{id}` - Get invoice details
- `DELETE /invoices/{id}` - Delete invoice
- `GET /invoices/stats/cache` - Get cache statistics

### Reports
- `POST /reports/generate` - Generate PDF report
- `GET /reports/download/{filename}` - Download report

### Health
- `GET /health` - Service health check

## Configuration

### Environment Variables

Required variables in `.env`:

```bash
# Database
DATABASE_URL=postgresql://user:password@host:5432/dbname

# Gemini API
GEMINI_API_KEY=your_api_key_here
GEMINI_FLASH_3=your_api_key_here

# Application
DEBUG=True
ENVIRONMENT=development
UPLOAD_DIR=./uploads
REPORTS_DIR=./reports

# AWS (for deployment)
AWS_REGION=ap-southeast-1
S3_BUCKET_NAME=invoice-ai-invoices-dev
```

### Terraform Variables

Required variables in `terraform.tfvars`:

```hcl
aws_region       = "ap-southeast-1"
environment      = "dev"
allowed_ssh_cidr = "YOUR_IP/32"
key_name         = "your-key-pair-name"
db_password      = "secure_password"
gemini_api_key   = "your_api_key"
```

## Deployment

### Infrastructure Updates

```bash
cd terraform
terraform plan
terraform apply
```

### Application Updates

After deploying your code to EC2:

```bash
ssh -i ~/.ssh/your-key.pem ec2-user@YOUR_EC2_IP
cd /home/ec2-user/invoice-ai-system
sudo docker-compose restart
```

### Monitoring

View CloudWatch logs and metrics in AWS Console:
- EC2 instance metrics
- RDS database performance
- Application logs

## Cost Estimation

### Free Tier (First 6 months)
- EC2 t3.micro: $0 (750 hours/month)
- RDS t3.micro: $0 (750 hours/month)
- S3 storage: $0 (5GB)
- Data transfer: $0 (100GB/month)

**Total: $0/month**

### After Free Tier
- EC2 t3.micro: ~$8/month
- RDS t3.micro: ~$15/month
- S3 + transfer: ~$2/month
- EBS storage: ~$2/month

**Total: ~$27/month**

## Security Considerations

- Database credentials stored in environment variables
- SSH access restricted to specific IP addresses
- S3 buckets configured with private access only
- API endpoints protected with CORS policies
- Terraform state contains sensitive data (keep secure)

## Troubleshooting

### Local Development

**Database connection error:**
```bash
# Restart PostgreSQL container
docker-compose restart postgres
```

**Port already in use:**
```bash
# Check what's using the port
lsof -i :8000
# Kill the process or change port in docker-compose.yml
```

### AWS Deployment

**SSH connection timeout:**
- Verify security group allows SSH from your IP
- Check your current IP: `curl ifconfig.me`
- Update security group or terraform.tfvars

**Database connection error:**
- Verify RDS is in "available" state
- Check security group allows PostgreSQL from EC2
- Verify credentials in docker-compose.yml

**Application not starting:**
```bash
# SSH into EC2
ssh -i ~/.ssh/your-key.pem ec2-user@YOUR_IP

# Check logs
sudo docker-compose logs -f

# Restart services
sudo docker-compose restart
```

## Next Update

- Fix the Generate Report issue
- Create a CI/CD using GitHub Actions
- Create a monitoring using AWS CloudWatch

## License

This project is licensed under the MIT License - see the LICENSE file for details.