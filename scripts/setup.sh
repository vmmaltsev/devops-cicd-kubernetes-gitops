#!/bin/bash

# DevOps CI/CD Kubernetes GitOps Setup Script
# This script automates the initial setup of the development environment

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    local missing_tools=()
    
    if ! command_exists docker; then
        missing_tools+=("docker")
    fi
    
    if ! command_exists docker-compose; then
        missing_tools+=("docker-compose")
    fi
    
    if ! command_exists python3; then
        missing_tools+=("python3")
    fi
    
    if ! command_exists pip3; then
        missing_tools+=("pip3")
    fi
    
    if ! command_exists git; then
        missing_tools+=("git")
    fi
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        log_error "Missing required tools: ${missing_tools[*]}"
        log_info "Please install the missing tools and run this script again."
        exit 1
    fi
    
    log_success "All prerequisites are installed"
}

# Setup environment file
setup_environment() {
    log_info "Setting up environment configuration..."
    
    if [ ! -f .env ]; then
        if [ -f env.example ]; then
            cp env.example .env
            log_success "Created .env file from env.example"
            log_warning "Please edit .env file with your actual values"
        else
            log_error "env.example file not found"
            exit 1
        fi
    else
        log_info ".env file already exists"
    fi
}

# Setup Python virtual environment
setup_python_env() {
    log_info "Setting up Python virtual environment..."
    
    if [ ! -d "src/venv" ]; then
        cd src
        python3 -m venv venv
        source venv/bin/activate
        
        if [ -f requirements.txt ]; then
            pip install -r requirements.txt
            log_success "Installed Python dependencies"
        fi
        
        cd ..
    else
        log_info "Python virtual environment already exists"
    fi
}

# Setup development dependencies
setup_dev_dependencies() {
    log_info "Setting up development dependencies..."
    
    if [ -f requirements-dev.txt ]; then
        cd src
        source venv/bin/activate
        pip install -r ../requirements-dev.txt
        cd ..
        log_success "Installed development dependencies"
    else
        log_warning "requirements-dev.txt not found, skipping dev dependencies"
    fi
}

# Setup pre-commit hooks
setup_pre_commit() {
    log_info "Setting up pre-commit hooks..."
    
    if [ -f .pre-commit-config.yaml ]; then
        cd src
        source venv/bin/activate
        pre-commit install
        cd ..
        log_success "Pre-commit hooks installed"
    else
        log_warning ".pre-commit-config.yaml not found, skipping pre-commit setup"
    fi
}

# Build Docker image
build_docker_image() {
    log_info "Building Docker image..."
    
    if [ -f Dockerfile ]; then
        docker build -t devops-app:latest .
        log_success "Docker image built successfully"
    else
        log_error "Dockerfile not found"
        exit 1
    fi
}

# Test application
test_application() {
    log_info "Running application tests..."
    
    if [ -d tests ]; then
        cd src
        source venv/bin/activate
        python -m pytest ../tests/ -v
        cd ..
        log_success "Tests completed"
    else
        log_warning "Tests directory not found, skipping tests"
    fi
}

# Start services with Docker Compose
start_services() {
    log_info "Starting services with Docker Compose..."
    
    if [ -f docker-compose.yml ]; then
        docker-compose up -d
        log_success "Services started successfully"
        log_info "Application should be available at http://localhost:8080"
    else
        log_error "docker-compose.yml not found"
        exit 1
    fi
}

# Health check
health_check() {
    log_info "Performing health check..."
    
    # Wait a bit for services to start
    sleep 10
    
    if curl -f http://localhost:8080/healthz >/dev/null 2>&1; then
        log_success "Application is healthy"
    else
        log_warning "Health check failed - application may still be starting"
    fi
}

# Main setup function
main() {
    log_info "Starting DevOps CI/CD Kubernetes GitOps setup..."
    
    check_prerequisites
    setup_environment
    setup_python_env
    setup_dev_dependencies
    setup_pre_commit
    build_docker_image
    test_application
    start_services
    health_check
    
    log_success "Setup completed successfully!"
    log_info "Next steps:"
    log_info "1. Edit .env file with your actual values"
    log_info "2. Access the application at http://localhost:8080"
    log_info "3. Check metrics at http://localhost:8080/metrics"
    log_info "4. View logs with: docker-compose logs -f"
}

# Run main function
main "$@" 