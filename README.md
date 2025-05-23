# DevOps CI/CD Kubernetes GitOps Demo

🚀 **Production-ready Flask application with comprehensive CI/CD pipeline, optimized Docker containers, and GitOps practices.**

## ✨ Features

- 🐍 **Flask Application** with Prometheus metrics
- 🐳 **Optimized Docker** with multi-stage builds (146MB image)
- 🔄 **Comprehensive CI/CD** with GitHub Actions
- 🛡️ **Security Scanning** (Bandit, Safety, Trivy)
- 📊 **Test Coverage** with pytest
- 🔍 **Code Quality** (Black, isort, flake8, mypy)
- 📈 **Monitoring** with Prometheus metrics
- 🔧 **GitOps Ready** for Kubernetes deployment

## 🚀 Quick Start

### Local Development

```bash
# Clone the repository
git clone <repository-url>
cd devops-cicd-kubernetes-gitops

# Set up environment
cp env.example .env
# Edit .env with your values

# Run with Docker Compose
docker-compose up -d

# Access the application
curl http://localhost:8080/healthz
```

### Development Setup

```bash
# Install development dependencies
pip install -r requirements-dev.txt

# Set up pre-commit hooks
pre-commit install

# Run tests
pytest tests/ -v --cov=src

# Run code quality checks
black src/
isort src/
flake8 src/
```

## 📊 CI/CD Pipeline

The pipeline includes 5 comprehensive jobs:

1. **🔍 Code Quality & Security** - Linting, formatting, security scans
2. **🧪 Tests** - Unit tests with coverage (Python 3.11 & 3.12)
3. **🐳 Docker Build & Security** - Image build, testing, vulnerability scanning
4. **🔗 Docker Compose Test** - Integration testing
5. **📋 Build Summary** - Reporting and notifications

### Pipeline Features

- ✅ **Matrix Testing** across Python versions
- ✅ **Parallel Execution** for faster feedback
- ✅ **Artifact Preservation** (coverage, security reports)
- ✅ **Security Integration** with GitHub Security tab
- ✅ **Build Caching** for performance optimization

## 🐳 Docker Optimizations

### Before vs After

| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| **Image Size** | 457MB | 146MB | 68% reduction |
| **Build Stages** | 1 | 2 (multi-stage) | Optimized |
| **Security** | Basic | Enhanced | Non-root, dumb-init |
| **Caching** | Poor | Optimized | Layer optimization |

### Key Improvements

- 🏗️ **Multi-stage builds** for smaller production images
- 🔒 **Security hardening** with non-root user and dumb-init
- 📦 **Dependency optimization** with separate build/runtime stages
- 🚀 **Performance tuning** with proper Gunicorn configuration

## 🛡️ Security Features

### Code Security
- **Bandit** - Python security vulnerability scanning
- **Safety** - Dependency vulnerability checking
- **MyPy** - Type safety validation

### Container Security
- **Trivy** - Container vulnerability scanning
- **Non-root execution** - Security best practices
- **Read-only filesystem** - Runtime protection

### Pipeline Security
- **SARIF integration** - GitHub Security tab
- **Artifact isolation** - Secure build artifacts
- **Secret management** - Proper credential handling

## 📁 Project Structure

```
├── .github/workflows/ci.yml    # CI/CD pipeline
├── src/                        # Application source
│   ├── app.py                 # Flask application
│   ├── config.py              # Configuration
│   ├── wsgi.py                # WSGI entry point
│   └── requirements.txt       # Dependencies
├── tests/                      # Test suite
│   └── test_app.py            # Comprehensive tests
├── Dockerfile                  # Optimized multi-stage build
├── docker-compose.yml          # Local development
├── pyproject.toml             # Tool configuration
├── requirements-dev.txt       # Development dependencies
├── .pre-commit-config.yaml    # Pre-commit hooks
└── env.example                # Environment template
```

## 📚 Documentation

- 📄 [Docker Improvements](DOCKER_IMPROVEMENTS.md) - Detailed Docker optimizations
- 📄 [CI/CD Improvements](CI_CD_IMPROVEMENTS.md) - Pipeline enhancements
- 🔧 [Configuration Guide](pyproject.toml) - Tool configurations

## 🔧 Environment Variables

### Required for Production
```bash
METRICS_USER=your_username      # Metrics endpoint authentication
METRICS_PASS=your_password      # Metrics endpoint password
```

### Optional
```bash
FLASK_ENV=production           # Application environment
WORKERS=3                      # Gunicorn workers
TIMEOUT=30                     # Request timeout
```

## 🚀 Deployment

### Docker
```bash
docker build -t myapp:latest .
docker run -p 8080:8080 myapp:latest
```

### Docker Compose
```bash
docker-compose up -d
```

### Kubernetes (GitOps)
```bash
# Apply Kubernetes manifests
kubectl apply -f k8s/
```

## 📈 Monitoring

- **Health Check**: `GET /healthz`
- **Metrics**: `GET /metrics` (Prometheus format)
- **Application**: `GET /` (main endpoint)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests and quality checks
5. Submit a pull request

### Development Workflow

```bash
# Install pre-commit hooks
pre-commit install

# Make changes
# ...

# Run quality checks
black src/
isort src/
flake8 src/
pytest tests/

# Commit (pre-commit hooks will run automatically)
git commit -m "feat: add new feature"
```

## 📊 Metrics & Performance

- **Test Coverage**: >80%
- **Security Scans**: 3 layers (code, dependencies, container)
- **Build Time**: ~5-8 minutes
- **Image Size**: 146MB (optimized)
- **Python Compatibility**: 3.11, 3.12

## 🔄 Continuous Improvement

- 🔄 **Weekly**: Dependency updates
- 🔄 **Monthly**: Security review
- 🔄 **Quarterly**: Tool evaluation

## 📞 Support

- 📧 **Issues**: Use GitHub Issues
- 📚 **Documentation**: See docs/ directory
- 🔧 **CI/CD Help**: Check pipeline logs and artifacts

---

**Built with ❤️ for DevOps excellence**