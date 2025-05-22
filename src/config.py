import os

class Config:
    HOST = os.getenv("FLASK_HOST", "0.0.0.0")
    PORT = int(os.getenv("FLASK_PORT", "8080"))
    DEBUG = os.getenv("FLASK_DEBUG", "false").lower() == "true"
    METRICS_USER = os.getenv("METRICS_USER", "metrics")
    METRICS_PASS = os.getenv("METRICS_PASS", "secret")
    PROMETHEUS_MULTIPROC_DIR = os.getenv("PROMETHEUS_MULTIPROC_DIR", "/tmp/prometheus")