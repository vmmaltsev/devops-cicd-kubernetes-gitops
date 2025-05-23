import os
import warnings


class Config:
    def __init__(self):
        self.HOST = os.getenv("FLASK_HOST", "0.0.0.0")
        self.PORT = int(os.getenv("FLASK_PORT", "8080"))
        self.DEBUG = os.getenv("FLASK_DEBUG", "false").lower() == "true"
        
        # ИСПРАВЛЕНИЕ: Улучшенная безопасность учетных данных
        self.METRICS_USER = os.getenv("METRICS_USER", "metrics")
        self.METRICS_PASS = os.getenv("METRICS_PASS", "secret")
        
        # Предупреждение о слабых учетных данных по умолчанию
        if self.METRICS_USER == "metrics" and self.METRICS_PASS == "secret":
            warnings.warn(
                "ВНИМАНИЕ: Используются учетные данные по умолчанию для метрик! "
                "Установите переменные окружения METRICS_USER и METRICS_PASS "
                "для повышения безопасности в продакшене.",
                UserWarning,
                stacklevel=3
            )
        
        self.PROMETHEUS_MULTIPROC_DIR = os.getenv(
            "PROMETHEUS_MULTIPROC_DIR", "/tmp/prometheus"
        )
    
    # Для обратной совместимости с Flask
    HOST = os.getenv("FLASK_HOST", "0.0.0.0")
    PORT = int(os.getenv("FLASK_PORT", "8080"))
    DEBUG = os.getenv("FLASK_DEBUG", "false").lower() == "true"
    METRICS_USER = os.getenv("METRICS_USER", "metrics")
    METRICS_PASS = os.getenv("METRICS_PASS", "secret")
    PROMETHEUS_MULTIPROC_DIR = os.getenv("PROMETHEUS_MULTIPROC_DIR", "/tmp/prometheus")
