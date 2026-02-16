#!/bin/bash
# =====================================================
# Deploy Script - Invoice AI System
# =====================================================

set -e  # Exit on error

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Check prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites"
    
    # Check Terraform
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform not installed"
        echo "Install from: https://www.terraform.io/downloads"
        exit 1
    fi
    print_success "Terraform installed: $(terraform version | head -n1)"
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI not installed"
        echo "Install from: https://aws.amazon.com/cli/"
        exit 1
    fi
    print_success "AWS CLI installed: $(aws --version)"
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials not configured"
        echo "Run: aws configure"
        exit 1
    fi
    print_success "AWS credentials configured"
    
    # Check terraform.tfvars
    if [ ! -f "terraform.tfvars" ]; then
        print_error "terraform.tfvars not found"
        echo "Copy terraform.tfvars.example to terraform.tfvars and update values"
        exit 1
    fi
    print_success "terraform.tfvars found"
    
    # Check for placeholder values
    if grep -q "YOUR_GEMINI_API_KEY_HERE" terraform.tfvars; then
        print_error "GEMINI_API_KEY not set in terraform.tfvars"
        echo "Update terraform.tfvars with your actual Gemini API key"
        exit 1
    fi
    
    if grep -q "ChangeMe123456" terraform.tfvars; then
        print_warning "Using default database password. Consider changing it!"
    fi
    
    echo ""
}

# Initialize Terraform
init_terraform() {
    print_header "Initializing Terraform"
    
    if terraform init; then
        print_success "Terraform initialized"
    else
        print_error "Terraform initialization failed"
        exit 1
    fi
    
    echo ""
}

# Validate Terraform
validate_terraform() {
    print_header "Validating Terraform Configuration"
    
    if terraform validate; then
        print_success "Configuration is valid"
    else
        print_error "Configuration validation failed"
        exit 1
    fi
    
    echo ""
}

# Plan deployment
plan_deployment() {
    print_header "Planning Deployment"
    
    terraform plan -out=tfplan
    
    echo ""
}

# Apply deployment
apply_deployment() {
    print_header "Applying Deployment"
    
    print_warning "This will create AWS resources"
    print_info "Estimated time: 10-15 minutes"
    echo ""
    
    read -p "Continue? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        print_info "Deployment cancelled"
        exit 0
    fi
    
    echo ""
    print_info "Starting deployment..."
    
    if terraform apply tfplan; then
        print_success "Deployment completed!"
    else
        print_error "Deployment failed"
        exit 1
    fi
    
    echo ""
}

# Display outputs
show_outputs() {
    print_header "Deployment Information"
    
    terraform output -json > outputs.json
    
    echo ""
    terraform output next_steps
    
    echo ""
    print_success "Outputs saved to outputs.json"
}

# Verify deployment
verify_deployment() {
    print_header "Verifying Deployment"
    
    print_info "Waiting 30 seconds for services to start..."
    sleep 30
    
    # Get EC2 IP
    EC2_IP=$(terraform output -raw ec2_public_ip)
    
    # Test FastAPI health
    print_info "Testing FastAPI health endpoint..."
    if curl -f -s "http://${EC2_IP}:8000/health" > /dev/null; then
        print_success "FastAPI is responding"
    else
        print_warning "FastAPI not responding yet (may still be starting)"
    fi
    
    # Test Streamlit
    print_info "Testing Streamlit endpoint..."
    if curl -f -s "http://${EC2_IP}:8501/_stcore/health" > /dev/null; then
        print_success "Streamlit is responding"
    else
        print_warning "Streamlit not responding yet (may still be starting)"
    fi
    
    echo ""
}

# Main execution
main() {
    clear
    print_header "Invoice AI System - Deployment Script"
    echo ""
    
    check_prerequisites
    init_terraform
    validate_terraform
    plan_deployment
    apply_deployment
    show_outputs
    verify_deployment
    
    print_header "Deployment Complete! 🎉"
    echo ""
    print_info "Access your application:"
    echo "  Streamlit: http://$(terraform output -raw ec2_public_ip):8501"
    echo "  FastAPI:   http://$(terraform output -raw ec2_public_ip):8000/docs"
    echo ""
    print_info "SSH command:"
    echo "  $(terraform output -raw ssh_command)"
    echo ""
    print_warning "Note: Allow 2-3 minutes for Docker containers to fully start"
    echo ""
}

# Run main function
main