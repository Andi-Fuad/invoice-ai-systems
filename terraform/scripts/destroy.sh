#!/bin/bash
# =====================================================
# Destroy Script - Invoice AI System
# WARNING: This will DELETE all AWS resources!
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

# Show current resources
show_resources() {
    print_header "Current Resources"
    
    if [ ! -f "terraform.tfstate" ]; then
        print_error "No Terraform state found. Nothing to destroy."
        exit 0
    fi
    
    echo ""
    print_info "The following resources will be DESTROYED:"
    echo ""
    
    terraform show -no-color | grep -E "^# |resource " | head -20
    
    echo ""
    echo "... and more"
    echo ""
}

# Create backup
backup_state() {
    print_header "Creating Backup"
    
    if [ -f "terraform.tfstate" ]; then
        BACKUP_NAME="terraform.tfstate.backup.$(date +%Y%m%d_%H%M%S)"
        cp terraform.tfstate "$BACKUP_NAME"
        print_success "State backed up to: $BACKUP_NAME"
    fi
    
    echo ""
}

# Confirmation
confirm_destroy() {
    print_header "⚠️  DANGER ZONE ⚠️"
    echo ""
    print_error "This will permanently DELETE:"
    echo "  • EC2 instance"
    echo "  • RDS database (and all data)"
    echo "  • S3 bucket (and all invoices)"
    echo "  • VPC and networking"
    echo "  • All associated resources"
    echo ""
    print_warning "This action CANNOT be undone!"
    echo ""
    
    read -p "Type 'delete' to confirm destruction: " confirm
    
    if [ "$confirm" != "delete" ]; then
        print_info "Destruction cancelled"
        exit 0
    fi
    
    echo ""
    read -p "Are you absolutely sure? (yes/no): " confirm2
    
    if [ "$confirm2" != "yes" ]; then
        print_info "Destruction cancelled"
        exit 0
    fi
    
    echo ""
}

# Destroy resources
destroy_resources() {
    print_header "Destroying Resources"
    
    print_info "Starting destruction process..."
    echo ""
    
    if terraform destroy -auto-approve; then
        print_success "All resources destroyed"
    else
        print_error "Destruction failed"
        print_warning "Some resources may still exist. Check AWS console."
        exit 1
    fi
    
    echo ""
}

# Clean up local files
cleanup_local() {
    print_header "Cleaning Up Local Files"
    
    read -p "Delete local Terraform files (.terraform, tfstate, etc.)? (yes/no): " cleanup
    
    if [ "$cleanup" = "yes" ]; then
        rm -rf .terraform
        rm -f .terraform.lock.hcl
        rm -f terraform.tfstate
        rm -f terraform.tfstate.backup*
        rm -f tfplan
        rm -f outputs.json
        print_success "Local files cleaned up"
    else
        print_info "Local files kept"
    fi
    
    echo ""
}

# Verify destruction
verify_destruction() {
    print_header "Verifying Destruction"
    
    print_info "Checking for remaining resources..."
    
    # Check EC2 instances
    INSTANCES=$(aws ec2 describe-instances \
        --filters "Name=tag:Project,Values=Invoice-AI-System" \
        --query "Reservations[].Instances[?State.Name!='terminated'].InstanceId" \
        --output text 2>/dev/null || echo "")
    
    if [ -z "$INSTANCES" ]; then
        print_success "No EC2 instances found"
    else
        print_warning "EC2 instances still exist: $INSTANCES"
    fi
    
    # Check RDS instances
    RDS=$(aws rds describe-db-instances \
        --query "DBInstances[?contains(DBInstanceIdentifier, 'invoice-ai')].DBInstanceIdentifier" \
        --output text 2>/dev/null || echo "")
    
    if [ -z "$RDS" ]; then
        print_success "No RDS instances found"
    else
        print_warning "RDS instances still exist: $RDS"
    fi
    
    # Check S3 buckets
    BUCKETS=$(aws s3 ls | grep invoice-ai | awk '{print $3}' || echo "")
    
    if [ -z "$BUCKETS" ]; then
        print_success "No S3 buckets found"
    else
        print_warning "S3 buckets still exist: $BUCKETS"
        echo ""
        read -p "Delete S3 buckets? (yes/no): " delete_s3
        if [ "$delete_s3" = "yes" ]; then
            for bucket in $BUCKETS; do
                aws s3 rb "s3://$bucket" --force
                print_success "Deleted bucket: $bucket"
            done
        fi
    fi
    
    echo ""
}

# Main execution
main() {
    clear
    print_header "Invoice AI System - Destroy Script"
    echo ""
    
    show_resources
    backup_state
    confirm_destroy
    destroy_resources
    verify_destruction
    cleanup_local
    
    print_header "Destruction Complete"
    echo ""
    print_success "All resources have been destroyed"
    print_info "State backup saved (if it existed)"
    echo ""
    print_warning "Remember:"
    echo "  • Check AWS console to verify all resources are gone"
    echo "  • Check your AWS billing dashboard"
    echo "  • Any manually created resources (key pairs, etc.) still exist"
    echo ""
}

# Run main function
main