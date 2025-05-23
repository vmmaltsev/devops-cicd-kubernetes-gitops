# Deployment Guide

## Prerequisites

### Local Development
- Docker and Docker Compose
- Python 3.11+ with pip
- Git

### Production Deployment
- Kubernetes cluster (1.24+)
- kubectl configured
- Helm 3.x
- ArgoCD (optional, for GitOps)

## Environment Configuration

### 1. Environment Variables

Copy and configure the environment file:
```bash
cp env.example .env
```

Required variables:
```bash
# Metrics authentication
METRICS_USER=your_secure_username
METRICS_PASS=your_secure_password

# Application settings (optional)
FLASK_ENV=production
DEBUG=false
HOST=0.0.0.0
PORT=8080
LOG_LEVEL=INFO
WORKERS=3
TIMEOUT=30
```

### 2. Security Considerations

⚠️ **Important Security Notes**:
- Never commit `.env` files to version control
- Use strong, unique passwords for production
- Rotate credentials regularly
- Use Kubernetes secrets for production deployments

## Local Development

### Docker Compose (Recommended)

```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

### Native Python

```bash
# Create virtual environment
python -m venv venv
source venv/bin/activate  # Linux/Mac
# or
venv\Scripts\activate     # Windows

# Install dependencies
pip install -r src/requirements.txt

# Run application
cd src
python app.py
```

## Container Deployment

### Build Docker Image

```bash
# Build optimized production image
docker build -t devops-app:latest .

# Build with specific tag
docker build -t devops-app:v1.0.0 .

# Multi-platform build
docker buildx build --platform linux/amd64,linux/arm64 -t devops-app:latest .
```

### Run Container

```bash
# Basic run
docker run -p 8080:8080 devops-app:latest

# With environment file
docker run --env-file .env -p 8080:8080 devops-app:latest

# With custom configuration
docker run -e METRICS_USER=admin -e METRICS_PASS=secret -p 8080:8080 devops-app:latest
```

## Kubernetes Deployment

### 1. Manual Deployment

```bash
# Create namespace
kubectl create namespace devops-app

# Apply manifests
kubectl apply -f k8s/ -n devops-app

# Verify deployment
kubectl get pods -n devops-app
kubectl get services -n devops-app
```

### 2. Helm Deployment

```bash
# Install with Helm
helm install devops-app helm/devops-app \
  --namespace devops-app \
  --create-namespace \
  --set image.tag=v1.0.0 \
  --set metrics.username=admin \
  --set metrics.password=secret

# Upgrade deployment
helm upgrade devops-app helm/devops-app \
  --set image.tag=v1.1.0

# Rollback deployment
helm rollback devops-app 1
```

### 3. GitOps with ArgoCD

```bash
# Install ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Apply ArgoCD application
kubectl apply -f argocd/application.yaml

# Access ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

## Production Deployment

### Infrastructure Setup

1. **Provision Infrastructure with Terraform**:
```bash
cd terraform/gcp-gke-cluster/envs/prod
terraform init
terraform plan
terraform apply
```

2. **Configure kubectl**:
```bash
gcloud container clusters get-credentials prod-cluster --region us-central1
```

3. **Install ArgoCD**:
```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

### Application Deployment

1. **Create Kubernetes Secrets**:
```bash
kubectl create secret generic app-secrets \
  --from-literal=metrics-user=admin \
  --from-literal=metrics-pass=secure-password \
  --namespace devops-app
```

2. **Deploy with ArgoCD**:
```bash
kubectl apply -f argocd/application-prod.yaml
```

3. **Verify Deployment**:
```bash
# Check application status
kubectl get pods -n devops-app
kubectl get ingress -n devops-app

# Check ArgoCD sync status
kubectl get application -n argocd
```

## Monitoring Setup

### 1. Prometheus and Grafana

```bash
# Install monitoring stack
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --values monitoring/prometheus-values.yaml
```

### 2. Import Dashboards

```bash
# Import Grafana dashboards
kubectl create configmap grafana-dashboards \
  --from-file=monitoring/grafana/dashboards/ \
  --namespace monitoring
```

### 3. Configure Alerts

```bash
# Apply AlertManager configuration
kubectl apply -f monitoring/alertmanager/ -n monitoring
```

## Health Checks and Verification

### Application Health

```bash
# Health check
curl http://localhost:8080/healthz

# Metrics endpoint
curl http://localhost:8080/metrics

# Application endpoint
curl http://localhost:8080/
```

### Kubernetes Health

```bash
# Pod status
kubectl get pods -n devops-app

# Service endpoints
kubectl get endpoints -n devops-app

# Ingress status
kubectl describe ingress -n devops-app
```

## Troubleshooting

### Common Issues

1. **Pod CrashLoopBackOff**:
```bash
# Check pod logs
kubectl logs -f deployment/devops-app -n devops-app

# Describe pod for events
kubectl describe pod <pod-name> -n devops-app
```

2. **Service Not Accessible**:
```bash
# Check service configuration
kubectl get svc -n devops-app

# Test service connectivity
kubectl run test-pod --image=busybox --rm -it -- wget -qO- http://devops-app:8080/healthz
```

3. **Image Pull Errors**:
```bash
# Check image pull secrets
kubectl get secrets -n devops-app

# Verify image exists
docker pull <image-name>
```

### Debugging Commands

```bash
# Get all resources
kubectl get all -n devops-app

# Check events
kubectl get events -n devops-app --sort-by='.lastTimestamp'

# Port forward for local testing
kubectl port-forward svc/devops-app 8080:8080 -n devops-app

# Execute into pod
kubectl exec -it deployment/devops-app -n devops-app -- /bin/bash
```

## Rollback Procedures

### Helm Rollback

```bash
# List releases
helm list -n devops-app

# View release history
helm history devops-app -n devops-app

# Rollback to previous version
helm rollback devops-app -n devops-app

# Rollback to specific revision
helm rollback devops-app 2 -n devops-app
```

### Kubernetes Rollback

```bash
# View rollout history
kubectl rollout history deployment/devops-app -n devops-app

# Rollback deployment
kubectl rollout undo deployment/devops-app -n devops-app

# Rollback to specific revision
kubectl rollout undo deployment/devops-app --to-revision=2 -n devops-app
```

### ArgoCD Rollback

```bash
# Sync to previous commit
argocd app sync devops-app --revision HEAD~1

# Or use ArgoCD UI to select previous revision
```

## Performance Tuning

### Resource Optimization

```yaml
# Recommended resource limits
resources:
  requests:
    memory: "128Mi"
    cpu: "100m"
  limits:
    memory: "256Mi"
    cpu: "200m"
```

### Horizontal Pod Autoscaler

```bash
# Create HPA
kubectl autoscale deployment devops-app \
  --cpu-percent=70 \
  --min=2 \
  --max=10 \
  -n devops-app
```

### Load Testing

```bash
# Install hey for load testing
go install github.com/rakyll/hey@latest

# Run load test
hey -n 1000 -c 10 http://localhost:8080/
``` 