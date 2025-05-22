import os
import signal
import logging
from functools import wraps
from flask import Flask, Response, request, abort
from prometheus_client import (
    CollectorRegistry, multiprocess,
    Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST
)
from flask_cors import CORS
from config import Config

def create_app(config_class=Config):
    # Настройка логирования
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s %(levelname)s %(message)s"
    )
    app = Flask(__name__)
    app.config.from_object(config_class)
    CORS(app)

    # Подготовка мультипроцессного реестра
    os.makedirs(app.config["PROMETHEUS_MULTIPROC_DIR"], exist_ok=True)
    registry = CollectorRegistry()
    multiprocess.MultiProcessCollector(registry)

    # Метрики
    REQUESTS = Counter(
        'hello_world_requests_total',
        'Total Hello World Requests',
        ['method', 'endpoint'],
        registry=registry
    )
    LATENCY = Histogram(
        'hello_request_latency_seconds',
        'Latency of Hello endpoint',
        ['endpoint'],
        registry=registry
    )
    ERRORS = Counter(
        'hello_errors_total',
        'Total errors in Hello endpoint',
        ['endpoint', 'error_type'],
        registry=registry
    )

    def metrics_auth(fn):
        @wraps(fn)
        def wrapper(*args, **kwargs):
            auth = request.authorization
            if not auth or auth.username != app.config["METRICS_USER"] \
               or auth.password != app.config["METRICS_PASS"]:
                return abort(401)
            return fn(*args, **kwargs)
        return wrapper

    @app.route("/")
    @LATENCY.labels(endpoint="/").time()
    def hello():
        REQUESTS.labels(method=request.method, endpoint=request.path).inc()
        try:
            return "Hello, DevOps-Kubernetes-GitOps!"
        except Exception as e:
            ERRORS.labels(
                endpoint=request.path,
                error_type=type(e).__name__
            ).inc()
            logging.exception("Error in hello endpoint")
            abort(500)

    @app.route("/metrics")
    @metrics_auth
    def metrics():
        data = generate_latest(registry)
        return Response(data, status=200, content_type=CONTENT_TYPE_LATEST)

    @app.route("/healthz")
    def liveness():
        return "OK", 200

    @app.route("/ready")
    def readiness():
        # Здесь можно добавить реальную проверку зависимостей
        return "READY", 200

    # Graceful shutdown
    def handle_signal(sig, frame):
        logging.info(f"Received signal {sig}, shutting down gracefully...")
        # Здесь можно подождать завершения работы воркеров
        exit(0)

    signal.signal(signal.SIGTERM, handle_signal)
    signal.signal(signal.SIGINT, handle_signal)

    return app


if __name__ == "__main__":
    app = create_app()
    app.run(
        host=app.config["HOST"],
        port=app.config["PORT"],
        debug=app.config["DEBUG"]
    )
