import logging
import os
import signal
import sys
from functools import wraps
from typing import Any, Callable

from flask import Flask, Response, abort, request
from flask_cors import CORS
from prometheus_client import (
    CONTENT_TYPE_LATEST,
    CollectorRegistry,
    Counter,
    Histogram,
    generate_latest,
    multiprocess,
)

from config import Config


def _setup_logging() -> None:
    """Setup application logging configuration."""
    logging.basicConfig(
        level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s"
    )


def _configure_app(app: Flask, config_class: type) -> None:
    """Configure Flask application with the provided config class."""
    if config_class == Config:
        config_instance = Config()
        app.config.from_object(config_instance)
    else:
        app.config.from_object(config_class)


def _setup_prometheus(app: Flask) -> CollectorRegistry:
    """Setup Prometheus multiprocess collector and return registry."""
    prometheus_dir = app.config["PROMETHEUS_MULTIPROC_DIR"]
    os.makedirs(prometheus_dir, exist_ok=True)
    os.environ.setdefault("PROMETHEUS_MULTIPROC_DIR", prometheus_dir)

    registry = CollectorRegistry()
    multiprocess.MultiProcessCollector(registry)
    return registry


def _create_metrics(registry: CollectorRegistry) -> tuple[Counter, Histogram, Counter]:
    """Create and return Prometheus metrics."""
    requests = Counter(
        "hello_world_requests_total",
        "Total Hello World Requests",
        ["method", "endpoint"],
        registry=registry,
    )
    latency = Histogram(
        "hello_request_latency_seconds",
        "Latency of Hello endpoint",
        ["endpoint"],
        registry=registry,
    )
    errors = Counter(
        "hello_errors_total",
        "Total errors in Hello endpoint",
        ["endpoint", "error_type"],
        registry=registry,
    )
    return requests, latency, errors


def _create_metrics_auth_decorator(app: Flask) -> Callable:
    """Create metrics authentication decorator."""

    def metrics_auth(fn: Callable[..., Any]) -> Callable[..., Any]:
        @wraps(fn)
        def wrapper(*args: Any, **kwargs: Any) -> Any:
            auth = request.authorization
            if not _is_valid_auth(auth, app):
                return abort(401)
            return fn(*args, **kwargs)

        return wrapper

    return metrics_auth


def _is_valid_auth(auth: Any, app: Flask) -> bool:
    """Check if authentication credentials are valid."""
    return (
        auth is not None
        and auth.username == app.config["METRICS_USER"]
        and auth.password == app.config["METRICS_PASS"]
    )


def _setup_signal_handlers() -> None:
    """Setup graceful shutdown signal handlers."""

    def handle_signal(sig: int, frame: Any) -> None:
        logging.info(f"Received signal {sig}, shutting down gracefully...")
        sys.exit(0)

    signal.signal(signal.SIGTERM, handle_signal)
    signal.signal(signal.SIGINT, handle_signal)


def _register_routes(
    app: Flask,
    registry: CollectorRegistry,
    requests_counter: Counter,
    latency_histogram: Histogram,
    errors_counter: Counter,
    metrics_auth: Callable,
) -> None:
    """Register all application routes."""

    @app.route("/")
    @latency_histogram.labels(endpoint="/").time()
    def hello() -> str:
        requests_counter.labels(method=request.method, endpoint=request.path).inc()
        try:
            return "Hello, DevOps-Kubernetes-GitOps!"
        except Exception as e:
            errors_counter.labels(
                endpoint=request.path, error_type=type(e).__name__
            ).inc()
            logging.exception("Error in hello endpoint")
            abort(500)

    @app.route("/metrics")
    @metrics_auth
    def metrics() -> Response:
        data = generate_latest(registry)
        return Response(data, status=200, content_type=CONTENT_TYPE_LATEST)

    @app.route("/healthz")
    def liveness() -> tuple[str, int]:
        return "OK", 200

    @app.route("/ready")
    def readiness() -> tuple[str, int]:
        return "READY", 200


def create_app(config_class: type = Config) -> Flask:
    """Create and configure Flask application."""
    _setup_logging()

    app = Flask(__name__)
    _configure_app(app, config_class)
    CORS(app)

    registry = _setup_prometheus(app)
    requests_counter, latency_histogram, errors_counter = _create_metrics(registry)
    metrics_auth = _create_metrics_auth_decorator(app)

    _register_routes(
        app, registry, requests_counter, latency_histogram, errors_counter, metrics_auth
    )
    _setup_signal_handlers()

    return app


if __name__ == "__main__":
    app = create_app()
    app.run(host=app.config["HOST"], port=app.config["PORT"], debug=app.config["DEBUG"])
