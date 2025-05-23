#!/bin/bash

# DevOps CI/CD Kubernetes Deployment Script
# This script automates deployment to Kubernetes environments

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
ENVIRONMENT="dev"
NAMESPACE=""
IMAGE_TAG="latest"
DRY_RUN=false
WAIT_TIMEOUT="300s"

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

# Show usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Deploy the DevOps application to Kubernetes

OPTIONS:
    -e, --environment ENV    Target environment (dev, staging, prod) [default: dev]
    -n, --namespace NS       Kubernetes namespace [default: devops-app-ENV]
    -t, --tag TAG           Docker image tag [default: latest]
    -d, --dry-run           Perform a dry run without applying changes
    -w, --wait TIMEOUT      Wait timeout for deployment [default: 300s]
    -h, --help              Show this help message

EXAMPLES:
    $0 -e dev -t v1.2.3
    $0 --environment prod --tag v1.0.0 --wait 600s
    $0 --dry-run --environment staging

EOF
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -e|--environment)
                ENVIRONMENT="$2"
                shift 2
                ;;
            -n|--namespace)
                NAMESPACE="$2"
                shift 2
                ;;
            -t|--tag)
                IMAGE_TAG="$2"
                shift 2
                ;;
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -w|--wait)
                WAIT_TIMEOUT="$2"
                shift 2
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
    
    # Set default namespace if not provided
    if [ -z "$NAMESPACE" ]; then
        NAMESPACE="devops-app-${ENVIRONMENT}"
    fi
}

# Validate environment
validate_environment() {
    case $ENVIRONMENT in
        dev|staging|prod)
            log_info "Deploying to environment: $ENVIRONMENT"
            ;;
        *)
            log_error "Invalid environment: $ENVIRONMENT. Must be dev, staging, or prod"
            exit 1
            ;;
    esac
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    if ! command -v kubectl >/dev/null 2>&1; then
        log_error "kubectl is not installed"
        exit 1
    fi
    
    if ! command -v kustomize >/dev/null 2>&1; then
        log_error "kustomize is not installed"
        exit 1
    fi
    
    # Check kubectl connectivity
    if ! kubectl cluster-info >/dev/null 2>&1; then
        log_error "Cannot connect to Kubernetes cluster"
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

# Validate manifests
validate_manifests() {
    log_info "Validating Kubernetes manifests..."
    
    local overlay_path="k8s/overlays/${ENVIRONMENT}"
    
    if [ ! -d "$overlay_path" ]; then
        log_error "Environment overlay not found: $overlay_path"
        exit 1
    fi
    
    # Validate with kustomize
    if ! kustomize build "$overlay_path" >/dev/null; then
        log_error "Kustomize validation failed"
        exit 1
    fi
    
    # Validate with kubectl
    if ! kustomize build "$overlay_path" | kubectl apply --dry-run=client -f - >/dev/null; then
        log_error "Kubectl validation failed"
        exit 1
    fi
    
    log_success "Manifest validation passed"
}

# Update image tag
update_image_tag() {
    if [ "$IMAGE_TAG" != "latest" ]; then
        log_info "Updating image tag to: $IMAGE_TAG"
        
        local overlay_path="k8s/overlays/${ENVIRONMENT}"
        cd "$overlay_path"
        
        # Update image tag in kustomization.yaml
        kustomize edit set image "devops-app=devops-app:${IMAGE_TAG}"
        
        cd - >/dev/null
        log_success "Image tag updated"
    fi
}

# Create namespace if it doesn't exist
create_namespace() {
    log_info "Ensuring namespace exists: $NAMESPACE"
    
    if ! kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
        if [ "$DRY_RUN" = true ]; then
            log_info "DRY RUN: Would create namespace $NAMESPACE"
        else
            kubectl create namespace "$NAMESPACE"
            log_success "Created namespace: $NAMESPACE"
        fi
    else
        log_info "Namespace already exists: $NAMESPACE"
    fi
}

# Deploy application
deploy_application() {
    log_info "Deploying application to $ENVIRONMENT environment..."
    
    local overlay_path="k8s/overlays/${ENVIRONMENT}"
    local kubectl_args=""
    
    if [ "$DRY_RUN" = true ]; then
        kubectl_args="--dry-run=server"
        log_info "DRY RUN: Simulating deployment"
    fi
    
    # Apply manifests
    kustomize build "$overlay_path" | kubectl apply $kubectl_args -n "$NAMESPACE" -f -
    
    if [ "$DRY_RUN" = false ]; then
        log_success "Application deployed successfully"
    else
        log_success "Dry run completed successfully"
    fi
}

# Wait for deployment
wait_for_deployment() {
    if [ "$DRY_RUN" = true ]; then
        log_info "DRY RUN: Skipping deployment wait"
        return
    fi
    
    log_info "Waiting for deployment to be ready (timeout: $WAIT_TIMEOUT)..."
    
    if kubectl wait --for=condition=available --timeout="$WAIT_TIMEOUT" deployment/devops-app -n "$NAMESPACE"; then
        log_success "Deployment is ready"
    else
        log_error "Deployment failed to become ready within timeout"
        exit 1
    fi
}

# Verify deployment
verify_deployment() {
    if [ "$DRY_RUN" = true ]; then
        log_info "DRY RUN: Skipping deployment verification"
        return
    fi
    
    log_info "Verifying deployment..."
    
    # Check pod status
    local pods_ready
    pods_ready=$(kubectl get pods -n "$NAMESPACE" -l app=devops-app --no-headers | grep -c "Running" || echo "0")
    
    if [ "$pods_ready" -gt 0 ]; then
        log_success "$pods_ready pod(s) are running"
    else
        log_error "No pods are running"
        kubectl get pods -n "$NAMESPACE" -l app=devops-app
        exit 1
    fi
    
    # Check service
    if kubectl get service devops-app -n "$NAMESPACE" >/dev/null 2>&1; then
        log_success "Service is available"
    else
        log_warning "Service not found"
    fi
}

# Show deployment status
show_status() {
    if [ "$DRY_RUN" = true ]; then
        return
    fi
    
    log_info "Deployment status:"
    echo
    kubectl get all -n "$NAMESPACE" -l app=devops-app
    echo
    
    # Show ingress if exists
    if kubectl get ingress -n "$NAMESPACE" >/dev/null 2>&1; then
        log_info "Ingress configuration:"
        kubectl get ingress -n "$NAMESPACE"
    fi
}

# Rollback deployment
rollback_deployment() {
    log_info "Rolling back deployment..."
    
    if kubectl rollout undo deployment/devops-app -n "$NAMESPACE"; then
        log_success "Rollback initiated"
        wait_for_deployment
    else
        log_error "Rollback failed"
        exit 1
    fi
}

# Main deployment function
main() {
    log_info "Starting Kubernetes deployment..."
    
    parse_args "$@"
    validate_environment
    check_prerequisites
    validate_manifests
    update_image_tag
    create_namespace
    deploy_application
    wait_for_deployment
    verify_deployment
    show_status
    
    if [ "$DRY_RUN" = false ]; then
        log_success "Deployment completed successfully!"
        log_info "Application deployed to namespace: $NAMESPACE"
        log_info "Environment: $ENVIRONMENT"
        log_info "Image tag: $IMAGE_TAG"
    else
        log_success "Dry run completed successfully!"
    fi
}

# Handle script interruption
trap 'log_error "Deployment interrupted"; exit 1' INT TERM

# Run main function
main "$@" 