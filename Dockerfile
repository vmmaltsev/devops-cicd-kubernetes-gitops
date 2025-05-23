# syntax=docker/dockerfile:1

# builder stage for installing dependencies and creating virtual environment
FROM python:3.12.10-slim AS builder

# Install build dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
         build-essential \
         curl \
         zlib1g-dev \
         zlib1g \
    && rm -rf /var/lib/apt/lists/*

# Create virtual environment
ENV VENV_PATH="/opt/venv"
RUN python -m venv $VENV_PATH

# Copy requirements first for better layer caching
COPY src/requirements.txt /tmp/requirements.txt

# Install Python dependencies
RUN . $VENV_PATH/bin/activate \
    && pip install --upgrade pip \
    && pip install --no-cache-dir -r /tmp/requirements.txt

# production stage with minimal runtime dependencies
FROM python:3.12.10-slim AS production

LABEL maintainer="DevOps Team <devops@company.com>" \
      version="1.0" \
      description="Python Flask application with Prometheus metrics" \
      org.opencontainers.image.source="https://github.com/company/devops-cicd-kubernetes-gitops"

# Install only runtime dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
         curl \
         dumb-init \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONOPTIMIZE=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    VENV_PATH="/opt/venv" \
    PATH="/opt/venv/bin:$PATH"

# Create non-root user and group with explicit UID/GID
RUN groupadd --system --gid 1001 appgroup \
    && useradd --system --uid 1001 --gid appgroup --no-log-init \
       --home-dir /app --shell /bin/false appuser

# Set working directory
WORKDIR /app

# Copy virtual environment from builder stage
COPY --from=builder --chown=appuser:appgroup $VENV_PATH $VENV_PATH

# Copy application code
COPY --chown=appuser:appgroup src/ /app/

# Create necessary directories and set permissions
RUN mkdir -p /tmp/prometheus \
    && chown -R appuser:appgroup /app /tmp/prometheus \
    && chmod 755 /tmp/prometheus

# Switch to non-root user
USER appuser

# Expose port
EXPOSE 8080

# Add health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8080/healthz || exit 1

# Use dumb-init to handle signals properly and run Gunicorn
ENTRYPOINT ["dumb-init", "--"]
CMD ["/opt/venv/bin/gunicorn", "--workers", "3", "--bind", "0.0.0.0:8080", "--timeout", "30", "--keep-alive", "2", "wsgi:app"]
