# syntax=docker/dockerfile:1
FROM python:3.12-slim AS base

LABEL maintainer="Your Name <you@example.com>" \
      version="1.0"

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
         build-essential \
         curl \
    && rm -rf /var/lib/apt/lists/*

ENV PYTHONUNBUFFERED=1 \
    PYTHONOPTIMIZE=1 \
    VENV_PATH="/opt/venv"

WORKDIR /app

COPY src/requirements.txt /app/
RUN python -m venv $VENV_PATH \
    && . $VENV_PATH/bin/activate \
    && pip install --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt

COPY src/ /app/

RUN addgroup --system appgroup \
    && adduser --system --ingroup appgroup appuser \
    && mkdir -p /tmp/prometheus \
    && chown -R appuser:appgroup /app /opt/venv /tmp/prometheus \
    && chmod 755 /tmp/prometheus

USER appuser
EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s \
  CMD . /opt/venv/bin/activate && curl -f http://localhost:8080/healthz || exit 1

# теперь запускаем Gunicorn на модуле wsgi:app
ENTRYPOINT ["/opt/venv/bin/gunicorn", "--workers", "3", "--bind", "0.0.0.0:8080", "wsgi:app"]
