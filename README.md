# DevOps CI/CD Kubernetes GitOps

A production-ready Flask application demonstrating modern DevOps practices with CI/CD, containerization, and GitOps workflows.

## 🚀 Quick Start

```bash
# Clone and setup
git clone <repository-url>
cd devops-cicd-kubernetes-gitops

# Automated setup
./scripts/setup.sh

# Or manual setup
cp env.example .env
docker-compose up -d

# Verify
curl http://localhost:8080/healthz
```

## 📁 Project Structure

```
├── .github/workflows/     # CI/CD pipelines
├── src/                   # Flask application
│   ├── app.py            # Main application
│   ├── config.py         # Configuration
│   ├── wsgi.py           # WSGI entry point
│   └── requirements.txt  # Python dependencies
├── tests/                 # Test suite
├── k8s/                   # Kubernetes manifests
│   ├── base/             # Base configurations
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── kustomization.yaml
│   └── overlays/         # Environment-specific configs
│       ├── dev/          # Development environment
│       ├── staging/      # Staging environment
│       └── prod/         # Production environment
├── helm/                  # Helm charts
├── terraform/             # Infrastructure as Code
├── monitoring/            # Observability configs
├── argocd/               # GitOps configurations
├── docs/                 # Documentation
│   ├── architecture.md  # System architecture
│   ├── deployment.md    # Deployment guide
│   ├── monitoring.md    # Monitoring setup
│   ├── gitops.md        # GitOps workflow
│   └── security-fixes.md # Security documentation
├── scripts/              # Automation scripts
│   ├── setup.sh         # Development setup
│   ├── deploy.sh        # Kubernetes deployment
│   └── security-check.sh # Security verification
├── Dockerfile            # Container definition
├── Dockerfile.secure     # Alternative secure Dockerfile
├── docker-compose.yml   # Local development
├── requirements-dev.txt # Development dependencies
└── pyproject.toml       # Tool configuration
```

## 🛠️ Development

```bash
# Setup development environment
python -m venv venv
source venv/bin/activate
pip install -r src/requirements.txt -r requirements-dev.txt

# Install pre-commit hooks
pre-commit install

# Run tests
pytest tests/ -v --cov=src

# Code quality
black src/ && isort src/ && flake8 src/
```

## 🐳 Docker

```bash
# Build optimized image (146MB)
docker build -t devops-app:latest .

# Build secure image (alternative)
docker build -f Dockerfile.secure -t devops-app:secure .

# Run container
docker run -p 8080:8080 devops-app:latest
```

## 🔒 Security

This project includes comprehensive security measures:

### CVE-2023-45853 Fix
- **Issue**: Critical zlib vulnerability (CVSS 9.8)
- **Solution**: Updated to zlib 1.3.1 with source compilation
- **Verification**: Run `./scripts/security-check.sh` to verify the fix

### Security Features
- Non-root container execution
- Minimal attack surface with slim base images
- Regular vulnerability scanning with Trivy
- Automated security updates in CI/CD
- Security headers and input validation

### Security Verification
```bash
# Run comprehensive security check
./scripts/security-check.sh devops-app:latest

# Manual vulnerability scan
trivy image devops-app:latest

# Check zlib version
docker run --rm devops-app:latest /bin/bash -c "strings /usr/local/lib/libz.so.1.3.1 | grep version"
```

See [Security Documentation](docs/security-fixes.md) for detailed information.

## ☸️ Kubernetes Deployment

```bash
# Deploy to development
./scripts/deploy.sh -e dev

# Deploy to production
./scripts/deploy.sh -e prod -t v1.0.0

# Or use kubectl directly
kubectl apply -k k8s/overlays/dev
```

## 📊 Monitoring

- **Health**: `GET /healthz`
- **Metrics**: `GET /metrics` (Prometheus format)
- **Grafana**: Available dashboards in `monitoring/`

## 🔧 Configuration

Required environment variables:
```bash
METRICS_USER=username
METRICS_PASS=password
```

See `env.example` for all options.

## 📚 Documentation

- [Architecture](docs/architecture.md) - System design and technology decisions
- [Deployment Guide](docs/deployment.md) - Complete deployment instructions
- [Monitoring Setup](docs/monitoring.md) - Observability and alerting
- [GitOps Workflow](docs/gitops.md) - GitOps practices with ArgoCD
- [Security Fixes](docs/security-fixes.md) - Security vulnerability documentation

## 🤝 Contributing

1. Fork the repository
2. Create feature branch
3. Make changes with tests
4. Submit pull request

## 📋 Scripts

- `./scripts/setup.sh` - Automated development environment setup
- `./scripts/deploy.sh` - Kubernetes deployment automation
- `./scripts/security-check.sh` - Security vulnerability verification

---

**Built for DevOps excellence** 🚀