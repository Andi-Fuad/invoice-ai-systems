#!/bin/bash

# Invoice AI System - Startup Script
# This script helps you quickly set up and run the Invoice AI System

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_header() {
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================================${NC}"
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
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed"
        echo "Please install Docker from: https://www.docker.com/products/docker-desktop/"
        exit 1
    fi
    print_success "Docker is installed: $(docker --version)"
    
    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose is not installed"
        echo "Please install Docker Compose from: https://docs.docker.com/compose/install/"
        exit 1
    fi
    print_success "Docker Compose is installed: $(docker-compose --version)"
    
    # Check if Docker daemon is running
    if ! docker info &> /dev/null; then
        print_error "Docker daemon is not running"
        echo "Please start Docker Desktop or Docker daemon"
        exit 1
    fi
    print_success "Docker daemon is running"
    
    echo ""
}

# Setup environment
setup_environment() {
    print_header "Setting Up Environment"
    
    # Check if .env exists
    if [ ! -f .env ]; then
        print_warning ".env file not found. Creating from template..."
        cp .env.example .env
        print_success "Created .env file"
        print_warning "Please edit .env and add your GEMINI_API_KEY before continuing"
        echo ""
        read -p "Press Enter after you've updated .env with your API key..."
    else
        print_success ".env file exists"
    fi
    
    # Check if GEMINI_API_KEY is set
    if grep -q "your_gemini_api_key_here" .env; then
        print_error "GEMINI_API_KEY not set in .env"
        print_info "Get your API key from: https://makersuite.google.com/app/apikey"
        exit 1
    fi
    
    # Create required directories
    print_info "Creating required directories..."
    mkdir -p uploads reports docker/postgres
    touch uploads/.gitkeep reports/.gitkeep
    print_success "Directories created"
    
    echo ""
}

# Build containers
build_containers() {
    print_header "Building Docker Containers"
    print_info "This may take a few minutes on first run..."
    
    if docker-compose build; then
        print_success "Containers built successfully"
    else
        print_error "Failed to build containers"
        exit 1
    fi
    
    echo ""
}

# Start services
start_services() {
    print_header "Starting Services"
    
    # Check if services are already running
    if docker-compose ps | grep -q "Up"; then
        print_warning "Services are already running"
        read -p "Do you want to restart? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_info "Restarting services..."
            docker-compose down
        else
            print_info "Keeping existing services"
            return
        fi
    fi
    
    # Start in detached mode
    if docker-compose up -d; then
        print_success "Services started successfully"
    else
        print_error "Failed to start services"
        exit 1
    fi
    
    echo ""
}

# Wait for services
wait_for_services() {
    print_header "Waiting for Services to be Ready"
    
    print_info "Waiting for PostgreSQL..."
    sleep 5
    for i in {1..30}; do
        if docker-compose exec -T postgres pg_isready -U invoice_admin -d invoice_admin &> /dev/null; then
            print_success "PostgreSQL is ready"
            break
        fi
        sleep 2
        echo -n "."
    done
    echo ""
    
    print_info "Waiting for FastAPI..."
    sleep 5
    for i in {1..30}; do
        if curl -f http://localhost:8000/health &> /dev/null; then
            print_success "FastAPI is ready"
            break
        fi
        sleep 2
        echo -n "."
    done
    echo ""
    
    print_info "Waiting for Streamlit..."
    sleep 5
    for i in {1..30}; do
        if curl -f http://localhost:8501/_stcore/health &> /dev/null; then
            print_success "Streamlit is ready"
            break
        fi
        sleep 2
        echo -n "."
    done
    echo ""
}

# Display access information
display_access_info() {
    print_header "🎉 Invoice AI System is Running!"
    
    echo ""
    echo -e "${GREEN}Access your application:${NC}"
    echo -e "  📱 Streamlit UI:    ${BLUE}http://localhost:8501${NC}"
    echo -e "  🔧 FastAPI Docs:    ${BLUE}http://localhost:8000/docs${NC}"
    echo -e "  💾 PostgreSQL:      ${BLUE}localhost:5432${NC}"
    echo -e "  📦 MinIO Console:   ${BLUE}http://localhost:9001${NC}"
    echo ""
    
    echo -e "${YELLOW}Useful commands:${NC}"
    echo "  View logs:          docker-compose logs -f"
    echo "  Stop services:      docker-compose down"
    echo "  Restart services:   docker-compose restart"
    echo "  View status:        docker-compose ps"
    echo ""
    
    print_info "Check DOCKER_SETUP.md for detailed documentation"
    echo ""
}

# Show logs
show_logs() {
    print_header "Showing Service Logs"
    print_info "Press Ctrl+C to exit logs"
    echo ""
    sleep 2
    docker-compose logs -f
}

# Main menu
main_menu() {
    while true; do
        print_header "Invoice AI System - Setup Script"
        echo ""
        echo "What would you like to do?"
        echo ""
        echo "  1) Quick Start (Check → Setup → Build → Run)"
        echo "  2) Check Prerequisites Only"
        echo "  3) Setup Environment Only"
        echo "  4) Build Containers Only"
        echo "  5) Start Services"
        echo "  6) Stop Services"
        echo "  7) View Logs"
        echo "  8) Restart Services"
        echo "  9) Clean Reset (Remove all data)"
        echo "  0) Exit"
        echo ""
        read -p "Enter your choice: " choice
        
        case $choice in
            1)
                check_prerequisites
                setup_environment
                build_containers
                start_services
                wait_for_services
                display_access_info
                read -p "Press Enter to view logs (Ctrl+C to exit)..."
                show_logs
                ;;
            2)
                check_prerequisites
                read -p "Press Enter to continue..."
                ;;
            3)
                setup_environment
                read -p "Press Enter to continue..."
                ;;
            4)
                build_containers
                read -p "Press Enter to continue..."
                ;;
            5)
                start_services
                wait_for_services
                display_access_info
                read -p "Press Enter to continue..."
                ;;
            6)
                print_info "Stopping services..."
                docker-compose down
                print_success "Services stopped"
                read -p "Press Enter to continue..."
                ;;
            7)
                show_logs
                ;;
            8)
                print_info "Restarting services..."
                docker-compose restart
                print_success "Services restarted"
                read -p "Press Enter to continue..."
                ;;
            9)
                print_warning "This will delete all data including database and uploaded files!"
                read -p "Are you sure? (type 'yes' to confirm): " confirm
                if [ "$confirm" = "yes" ]; then
                    print_info "Stopping and removing all containers, volumes, and images..."
                    docker-compose down -v --rmi all
                    rm -rf uploads/* reports/*
                    print_success "Clean reset completed"
                else
                    print_info "Reset cancelled"
                fi
                read -p "Press Enter to continue..."
                ;;
            0)
                print_info "Goodbye!"
                exit 0
                ;;
            *)
                print_error "Invalid choice. Please try again."
                sleep 2
                ;;
        esac
        
        clear
    done
}

# Run main menu
clear
main_menu