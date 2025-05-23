import logging
import os
import signal
import sys
from functools import wraps

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


def create_app(config_class=Config):
    # Настройка логирования
    logging.basicConfig(
        level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s"
    )
    app = Flask(__name__)

    # ИСПРАВЛЕНИЕ: Создаем экземпляр конфигурации для активации предупреждений
    if config_class == Config:
        config_instance = Config()
        app.config.from_object(config_instance)
    else:
        app.config.from_object(config_class)

    CORS(app)

    # Подготовка мультипроцессного реестра
    # ИСПРАВЛЕНИЕ: Устанавливаем переменную окружения ПЕРЕД созданием MultiProcessCollector
    prometheus_dir = app.config["PROMETHEUS_MULTIPROC_DIR"]
    os.makedirs(prometheus_dir, exist_ok=True)
    os.environ.setdefault("PROMETHEUS_MULTIPROC_DIR", prometheus_dir)

    registry = CollectorRegistry()
    multiprocess.MultiProcessCollector(registry)

    # Метрики
    REQUESTS = Counter(
        "hello_world_requests_total",
        "Total Hello World Requests",
        ["method", "endpoint"],
        registry=registry,
    )
    LATENCY = Histogram(
        "hello_request_latency_seconds",
        "Latency of Hello endpoint",
        ["endpoint"],
        registry=registry,
    )
    ERRORS = Counter(
        "hello_errors_total",
        "Total errors in Hello endpoint",
        ["endpoint", "error_type"],
        registry=registry,
    )

    def metrics_auth(fn):
        @wraps(fn)
        def wrapper(*args, **kwargs):
            auth = request.authorization
            if (
                not auth
                or auth.username != app.config["METRICS_USER"]
                or auth.password != app.config["METRICS_PASS"]
            ):
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
            ERRORS.labels(endpoint=request.path, error_type=type(e).__name__).inc()
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

    # ИСПРАВЛЕНИЕ: Улучшенная обработка graceful shutdown
    def handle_signal(sig, frame):
        logging.info(f"Received signal {sig}, shutting down gracefully...")
        # Здесь можно подождать завершения работы воркеров
        sys.exit(0)

    signal.signal(signal.SIGTERM, handle_signal)
    signal.signal(signal.SIGINT, handle_signal)

    return app


if __name__ == "__main__":
    app = create_app()
    app.run(host=app.config["HOST"], port=app.config["PORT"], debug=app.config["DEBUG"])
