# src/wsgi.py

from app import create_app

# создаём приложение один раз
app = create_app()
