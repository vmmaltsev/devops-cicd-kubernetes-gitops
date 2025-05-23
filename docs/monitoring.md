# Monitoring and Observability

## Overview

This document describes the monitoring and observability stack for the DevOps application, including metrics collection, visualization, alerting, and troubleshooting.

## Monitoring Stack

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Application   │───▶│   Prometheus    │───▶│    Grafana      │
│   (Metrics)     │    │   (Collection)  │    │ (Visualization) │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│     Logs        │    │  AlertManager   │    │   Dashboards    │
│  (Structured)   │    │   (Alerting)    │    │   (Custom)      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Application Metrics

### Built-in Metrics

The application exposes Prometheus metrics at `/metrics` endpoint:

```python
# Custom metrics examples
from prometheus_client import Counter, Histogram, Gauge

# Request counters
http_requests_total = Counter('http_requests_total', 'Total HTTP requests', ['method', 'endpoint'])

# Response time histogram
http_request_duration_seconds = Histogram('http_request_duration_seconds', 'HTTP request duration')

# Active connections gauge
active_connections = Gauge('active_connections', 'Active connections')
```

### Available Metrics

| Metric | Type | Description |
|--------|------|-------------|
| `http_requests_total` | Counter | Total HTTP requests by method and endpoint |
| `http_request_duration_seconds` | Histogram | Request duration in seconds |
| `active_connections` | Gauge | Current active connections |
| `python_info` | Info | Python version information |
| `process_*` | Various | Process-level metrics (CPU, memory, etc.) |

### Health Endpoints

- **Health Check**: `GET /healthz` - Application health status
- **Metrics**: `GET /metrics` - Prometheus metrics
- **Ready Check**: `GET /ready` - Readiness probe endpoint

## Prometheus Configuration

### Scrape Configuration

```yaml
# prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'devops-app'
    static_configs:
      - targets: ['devops-app:8080']
    metrics_path: '/metrics'
    scrape_interval: 10s
    
  - job_name: 'kubernetes-pods'
    kubernetes_sd_configs:
      - role: pod
    relabel_configs:
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
        action: keep
        regex: true
```

### Recording Rules

```yaml
# recording-rules.yml
groups:
  - name: devops-app.rules
    rules:
      - record: devops_app:http_requests:rate5m
        expr: rate(http_requests_total[5m])
        
      - record: devops_app:http_request_duration:p95
        expr: histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))
```

## Grafana Dashboards

### Application Dashboard

Key panels include:

1. **Request Rate**: Requests per second over time
2. **Response Time**: P50, P95, P99 latencies
3. **Error Rate**: 4xx and 5xx error percentages
4. **Throughput**: Total requests and data transfer
5. **Resource Usage**: CPU and memory consumption

### Infrastructure Dashboard

1. **Pod Status**: Running, pending, failed pods
2. **Node Metrics**: CPU, memory, disk usage
3. **Network**: Ingress/egress traffic
4. **Storage**: Persistent volume usage

### Custom Queries

```promql
# Request rate by endpoint
rate(http_requests_total[5m])

# Error rate percentage
rate(http_requests_total{status=~"4.."}[5m]) / rate(http_requests_total[5m]) * 100

# 95th percentile response time
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))

# Memory usage percentage
(container_memory_usage_bytes / container_spec_memory_limit_bytes) * 100
```

## Alerting Rules

### Critical Alerts

```yaml
# alerts.yml
groups:
  - name: devops-app.alerts
    rules:
      - alert: HighErrorRate
        expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.1
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "High error rate detected"
          description: "Error rate is {{ $value }} errors per second"

      - alert: HighResponseTime
        expr: histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m])) > 1
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High response time detected"
          description: "95th percentile response time is {{ $value }}s"

      - alert: PodCrashLooping
        expr: rate(kube_pod_container_status_restarts_total[15m]) > 0
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Pod is crash looping"
          description: "Pod {{ $labels.pod }} is restarting frequently"
```

### Warning Alerts

```yaml
      - alert: HighMemoryUsage
        expr: (container_memory_usage_bytes / container_spec_memory_limit_bytes) * 100 > 80
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "High memory usage"
          description: "Memory usage is {{ $value }}%"

      - alert: LowDiskSpace
        expr: (node_filesystem_avail_bytes / node_filesystem_size_bytes) * 100 < 20
        for: 15m
        labels:
          severity: warning
        annotations:
          summary: "Low disk space"
          description: "Disk space is {{ $value }}% full"
```

## AlertManager Configuration

### Routing Configuration

```yaml
# alertmanager.yml
global:
  smtp_smarthost: 'localhost:587'
  smtp_from: 'alerts@company.com'

route:
  group_by: ['alertname']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 1h
  receiver: 'web.hook'
  routes:
    - match:
        severity: critical
      receiver: 'critical-alerts'
    - match:
        severity: warning
      receiver: 'warning-alerts'

receivers:
  - name: 'critical-alerts'
    email_configs:
      - to: 'oncall@company.com'
        subject: 'CRITICAL: {{ .GroupLabels.alertname }}'
        body: |
          {{ range .Alerts }}
          Alert: {{ .Annotations.summary }}
          Description: {{ .Annotations.description }}
          {{ end }}
    
  - name: 'warning-alerts'
    slack_configs:
      - api_url: 'YOUR_SLACK_WEBHOOK_URL'
        channel: '#alerts'
        title: 'Warning Alert'
        text: '{{ .CommonAnnotations.summary }}'
```

## Log Management

### Structured Logging

```python
import logging
import json
from datetime import datetime

class JSONFormatter(logging.Formatter):
    def format(self, record):
        log_entry = {
            'timestamp': datetime.utcnow().isoformat(),
            'level': record.levelname,
            'message': record.getMessage(),
            'module': record.module,
            'function': record.funcName,
            'line': record.lineno
        }
        return json.dumps(log_entry)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    handlers=[logging.StreamHandler()],
    format='%(message)s'
)
logger = logging.getLogger(__name__)
logger.handlers[0].setFormatter(JSONFormatter())
```

### Log Aggregation

For production environments, consider:

1. **Fluentd/Fluent Bit**: Log collection and forwarding
2. **Elasticsearch**: Log storage and indexing
3. **Kibana**: Log visualization and search
4. **Loki**: Lightweight log aggregation (Grafana ecosystem)

## Performance Monitoring

### Key Performance Indicators (KPIs)

1. **Availability**: Uptime percentage (target: 99.9%)
2. **Response Time**: P95 latency (target: <500ms)
3. **Throughput**: Requests per second
4. **Error Rate**: Error percentage (target: <1%)
5. **Resource Utilization**: CPU/Memory usage

### SLA Monitoring

```promql
# Availability (uptime percentage)
avg_over_time(up[24h]) * 100

# Error budget calculation
1 - (rate(http_requests_total{status=~"5.."}[30d]) / rate(http_requests_total[30d]))

# Apdex score (Application Performance Index)
(
  sum(rate(http_request_duration_seconds_bucket{le="0.5"}[5m])) +
  sum(rate(http_request_duration_seconds_bucket{le="2.0"}[5m])) / 2
) / sum(rate(http_request_duration_seconds_count[5m]))
```

## Troubleshooting Guide

### Common Issues

1. **High Memory Usage**:
   ```bash
   # Check memory usage
   kubectl top pods -n devops-app
   
   # Analyze memory leaks
   kubectl exec -it <pod> -- python -m memory_profiler app.py
   ```

2. **Slow Response Times**:
   ```bash
   # Check application logs
   kubectl logs -f deployment/devops-app -n devops-app
   
   # Profile application
   kubectl exec -it <pod> -- python -m cProfile -o profile.stats app.py
   ```

3. **High Error Rates**:
   ```bash
   # Check error logs
   kubectl logs --previous deployment/devops-app -n devops-app | grep ERROR
   
   # Check dependencies
   kubectl get endpoints -n devops-app
   ```

### Debugging Commands

```bash
# Check Prometheus targets
kubectl port-forward svc/prometheus 9090:9090 -n monitoring
# Visit http://localhost:9090/targets

# Check AlertManager
kubectl port-forward svc/alertmanager 9093:9093 -n monitoring
# Visit http://localhost:9093

# Check Grafana
kubectl port-forward svc/grafana 3000:3000 -n monitoring
# Visit http://localhost:3000 (admin/admin)

# Export metrics for analysis
curl http://localhost:8080/metrics > metrics.txt
```

## Monitoring Best Practices

### Metrics Design

1. **Use appropriate metric types**:
   - Counters for cumulative values
   - Gauges for current values
   - Histograms for distributions

2. **Label wisely**:
   - Keep cardinality low
   - Use meaningful label names
   - Avoid high-cardinality labels

3. **Monitor the four golden signals**:
   - Latency
   - Traffic
   - Errors
   - Saturation

### Alert Design

1. **Alert on symptoms, not causes**
2. **Make alerts actionable**
3. **Avoid alert fatigue**
4. **Use appropriate severity levels**
5. **Include runbook links**

### Dashboard Design

1. **Start with overview dashboards**
2. **Use consistent time ranges**
3. **Include context and annotations**
4. **Make dashboards self-explanatory**
5. **Regular dashboard reviews**

## Monitoring Checklist

- [ ] Application metrics exposed
- [ ] Prometheus scraping configured
- [ ] Grafana dashboards created
- [ ] Critical alerts defined
- [ ] AlertManager configured
- [ ] Log aggregation setup
- [ ] SLA monitoring in place
- [ ] Runbooks documented
- [ ] Team trained on tools
- [ ] Regular monitoring reviews scheduled
