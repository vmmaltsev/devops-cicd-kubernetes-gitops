# GitOps Workflow

## Overview

GitOps is a declarative approach to continuous deployment where the desired state of the system is stored in Git repositories and automatically synchronized to the target environment.

## GitOps Principles

1. **Declarative**: System state described declaratively
2. **Versioned**: All changes tracked in Git
3. **Automated**: Changes applied automatically
4. **Observable**: System state continuously monitored

## Workflow Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Developer     │    │   Git Repository│    │   ArgoCD        │
│   Commits       │───▶│   (Source)      │───▶│   (Controller)  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │                       │
                                │                       │
                                ▼                       ▼
                       ┌─────────────────┐    ┌─────────────────┐
                       │   CI Pipeline   │    │   Kubernetes    │
                       │   (Build/Test)  │    │   Cluster       │
                       └─────────────────┘    └─────────────────┘
```

## Repository Structure

### Application Repository
```
devops-cicd-kubernetes-gitops/
├── src/                    # Application source code
├── tests/                  # Test suites
├── Dockerfile             # Container definition
├── .github/workflows/     # CI pipelines
└── k8s/                   # Kubernetes manifests
    ├── base/              # Base configurations
    └── overlays/          # Environment-specific configs
        ├── dev/
        ├── staging/
        └── prod/
```

### GitOps Repository (Optional)
```
gitops-config/
├── applications/          # ArgoCD applications
├── environments/          # Environment configs
│   ├── dev/
│   ├── staging/
│   └── prod/
└── infrastructure/        # Infrastructure manifests
```

## ArgoCD Setup

### Installation

```bash
# Create namespace
kubectl create namespace argocd

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for pods to be ready
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

# Get initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

### Access ArgoCD UI

```bash
# Port forward to access UI
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Or create ingress
kubectl apply -f argocd/ingress.yaml
```

### CLI Installation

```bash
# Install ArgoCD CLI
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd

# Login
argocd login localhost:8080
```

## Application Configuration

### ArgoCD Application Manifest

```yaml
# argocd/application.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: devops-app
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://github.com/your-org/devops-cicd-kubernetes-gitops
    targetRevision: main
    path: k8s/overlays/dev
  destination:
    server: https://kubernetes.default.svc
    namespace: devops-app
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
      - PrunePropagationPolicy=foreground
      - PruneLast=true
```

### Environment-Specific Applications

```yaml
# argocd/application-prod.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: devops-app-prod
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/your-org/devops-cicd-kubernetes-gitops
    targetRevision: main
    path: k8s/overlays/prod
  destination:
    server: https://kubernetes.default.svc
    namespace: devops-app-prod
  syncPolicy:
    automated:
      prune: true
      selfHeal: false  # Manual approval for prod
    syncOptions:
      - CreateNamespace=true
```

## Kustomize Structure

### Base Configuration

```yaml
# k8s/base/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - deployment.yaml
  - service.yaml
  - configmap.yaml
  - secret.yaml

commonLabels:
  app: devops-app
  version: v1.0.0
```

### Environment Overlays

```yaml
# k8s/overlays/dev/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: devops-app-dev

resources:
  - ../../base

patchesStrategicMerge:
  - deployment-patch.yaml

images:
  - name: devops-app
    newTag: dev-latest

replicas:
  - name: devops-app
    count: 1
```

```yaml
# k8s/overlays/prod/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: devops-app-prod

resources:
  - ../../base
  - ingress.yaml
  - hpa.yaml

patchesStrategicMerge:
  - deployment-patch.yaml

images:
  - name: devops-app
    newTag: v1.0.0

replicas:
  - name: devops-app
    count: 3
```

## CI/CD Integration

### GitHub Actions Workflow

```yaml
# .github/workflows/gitops.yml
name: GitOps Deployment

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Build and Push Image
        run: |
          docker build -t ${{ secrets.REGISTRY }}/devops-app:${{ github.sha }} .
          docker push ${{ secrets.REGISTRY }}/devops-app:${{ github.sha }}
      
      - name: Update Kustomization
        run: |
          cd k8s/overlays/dev
          kustomize edit set image devops-app=${{ secrets.REGISTRY }}/devops-app:${{ github.sha }}
          
      - name: Commit and Push
        run: |
          git config --local user.email "action@github.com"
          git config --local user.name "GitHub Action"
          git add k8s/overlays/dev/kustomization.yaml
          git commit -m "Update dev image to ${{ github.sha }}"
          git push
```

### Image Updater

```yaml
# argocd/image-updater.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-image-updater-config
  namespace: argocd
data:
  registries.conf: |
    registries:
      - name: Docker Hub
        prefix: docker.io
        api_url: https://registry-1.docker.io
        credentials: secret:argocd/docker-hub-creds#creds
        default: true
```

## Deployment Strategies

### Rolling Updates

```yaml
# Default rolling update strategy
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 25%
      maxSurge: 25%
```

### Blue-Green Deployment

```yaml
# Blue-Green with ArgoCD Rollouts
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: devops-app
spec:
  replicas: 3
  strategy:
    blueGreen:
      activeService: devops-app-active
      previewService: devops-app-preview
      autoPromotionEnabled: false
      scaleDownDelaySeconds: 30
      prePromotionAnalysis:
        templates:
        - templateName: success-rate
        args:
        - name: service-name
          value: devops-app-preview
      postPromotionAnalysis:
        templates:
        - templateName: success-rate
        args:
        - name: service-name
          value: devops-app-active
```

### Canary Deployment

```yaml
# Canary deployment strategy
spec:
  strategy:
    canary:
      steps:
      - setWeight: 20
      - pause: {}
      - setWeight: 40
      - pause: {duration: 10}
      - setWeight: 60
      - pause: {duration: 10}
      - setWeight: 80
      - pause: {duration: 10}
```

## Monitoring and Observability

### ArgoCD Metrics

```yaml
# ServiceMonitor for ArgoCD
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: argocd-metrics
  namespace: argocd
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: argocd-metrics
  endpoints:
  - port: metrics
```

### Application Health Checks

```yaml
# Custom health check
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-cm
  namespace: argocd
data:
  resource.customizations.health.argoproj.io_Rollout: |
    hs = {}
    if obj.status ~= nil then
      if obj.status.replicas ~= nil and obj.status.updatedReplicas ~= nil and obj.status.availableReplicas ~= nil then
        if obj.status.replicas == obj.status.updatedReplicas and obj.status.replicas == obj.status.availableReplicas then
          hs.status = "Healthy"
          hs.message = "Rollout is healthy"
          return hs
        end
      end
    end
    hs.status = "Progressing"
    hs.message = "Rollout is progressing"
    return hs
```

## Security Best Practices

### RBAC Configuration

```yaml
# ArgoCD RBAC policy
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-rbac-cm
  namespace: argocd
data:
  policy.default: role:readonly
  policy.csv: |
    p, role:admin, applications, *, */*, allow
    p, role:admin, clusters, *, *, allow
    p, role:admin, repositories, *, *, allow
    
    p, role:developer, applications, get, */*, allow
    p, role:developer, applications, sync, dev/*, allow
    
    g, devops-team, role:admin
    g, dev-team, role:developer
```

### Repository Access

```yaml
# Repository secret
apiVersion: v1
kind: Secret
metadata:
  name: private-repo
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: repository
stringData:
  type: git
  url: https://github.com/private/repo
  password: your-token
  username: not-used
```

## Troubleshooting

### Common Issues

1. **Application Out of Sync**:
```bash
# Check application status
argocd app get devops-app

# Force sync
argocd app sync devops-app

# Hard refresh
argocd app sync devops-app --force
```

2. **Sync Failures**:
```bash
# Check sync logs
kubectl logs -f deployment/argocd-application-controller -n argocd

# Describe application
kubectl describe application devops-app -n argocd
```

3. **Resource Conflicts**:
```bash
# Check resource differences
argocd app diff devops-app

# Prune orphaned resources
argocd app sync devops-app --prune
```

### Debugging Commands

```bash
# List applications
argocd app list

# Get application details
argocd app get devops-app

# View application logs
argocd app logs devops-app

# Check cluster connectivity
argocd cluster list

# Validate manifests
kubectl apply --dry-run=client -f k8s/
```

## Best Practices

### Repository Management

1. **Separate application and config repositories**
2. **Use semantic versioning for releases**
3. **Implement branch protection rules**
4. **Regular dependency updates**

### Application Design

1. **Use Kustomize for environment management**
2. **Implement proper health checks**
3. **Define resource limits and requests**
4. **Use secrets for sensitive data**

### Deployment Safety

1. **Implement automated testing**
2. **Use staging environments**
3. **Monitor deployment metrics**
4. **Have rollback procedures ready**

### Security

1. **Limit ArgoCD permissions**
2. **Use private repositories**
3. **Implement image scanning**
4. **Regular security audits**

## GitOps Checklist

- [ ] ArgoCD installed and configured
- [ ] Repository structure organized
- [ ] Kustomize overlays for environments
- [ ] Application manifests created
- [ ] CI/CD pipeline integrated
- [ ] Monitoring and alerting setup
- [ ] RBAC policies configured
- [ ] Security scanning enabled
- [ ] Rollback procedures tested
- [ ] Team training completed
