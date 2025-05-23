# Docker Compose Command Not Found Fix

## 🚨 Проблема
CI/CD pipeline падал с ошибкой:
```
/home/runner/work/_temp/dfafbd4f-8a0b-4452-9e69-96ef89644979.sh: line 1: docker-compose: command not found
Error: Process completed with exit code 127.
```

## 🔍 Причины проблемы

Согласно [Docker Community Forums](https://forums.docker.com/t/command-not-found-when-i-try-to-run-docker-compose/97183) и [KodeKloud](https://kodekloud.com/blog/docker-compose-command-not-found/), проблема может быть вызвана:

### 1. Изменение синтаксиса Docker Compose
- **Docker Compose V1**: `docker-compose` (с дефисом)
- **Docker Compose V2**: `docker compose` (с пробелом)

### 2. Отсутствие Docker Compose
- Docker Compose может быть не установлен как отдельный компонент
- В новых версиях Docker Desktop, Compose V2 встроен как плагин

### 3. Архитектурные различия
- Некоторые архитектуры могут не поддерживать определённые версии

## ✅ Решение

### 1. Обновлён синтаксис команд
Заменили старый синтаксис на новый:

```yaml
# ❌ Старый способ (V1)
- name: Run Docker Compose
  run: docker-compose up -d

# ✅ Новый способ (V2)
- name: Run Docker Compose
  run: docker compose up -d
```

### 2. Добавлен fallback механизм
Для обеспечения совместимости с обеими версиями:

```yaml
- name: Run Docker Compose
  run: |
    # Try modern Docker Compose syntax (V2) first, fallback to V1 if needed
    if docker compose version >/dev/null 2>&1; then
      echo "Using Docker Compose V2 syntax"
      docker compose up -d
    elif docker-compose --version >/dev/null 2>&1; then
      echo "Using Docker Compose V1 syntax"
      docker-compose up -d
    else
      echo "Error: Neither docker compose nor docker-compose found"
      exit 1
    fi
    sleep 15
```

### 3. Добавлена диагностика
Проверка доступных версий Docker Compose:

```yaml
- name: Check Docker Compose version
  run: |
    # Check which Docker Compose syntax is available
    docker compose version || docker-compose --version || echo "Neither docker compose nor docker-compose found"
```

## 🔧 Исправленные команды

### До исправления:
```bash
docker-compose up -d
docker-compose logs web
docker-compose down -v
```

### После исправления:
```bash
# Автоматический выбор правильного синтаксиса
if docker compose version >/dev/null 2>&1; then
  docker compose up -d
  docker compose logs web
  docker compose down -v
else
  docker-compose up -d
  docker-compose logs web
  docker-compose down -v
fi
```

## 📊 Совместимость

| Версия Docker | Синтаксис | Статус |
|---------------|-----------|---------|
| Docker Desktop (новые версии) | `docker compose` | ✅ Поддерживается |
| Docker Engine + Compose V2 | `docker compose` | ✅ Поддерживается |
| Docker Engine + Compose V1 | `docker-compose` | ✅ Fallback |
| Старые установки | `docker-compose` | ✅ Fallback |

## 🚀 Преимущества решения

✅ **Обратная совместимость** - работает с обеими версиями
✅ **Автоматическое определение** - выбирает правильный синтаксис
✅ **Диагностика** - показывает какая версия используется
✅ **Надёжность** - fallback на старый синтаксис при необходимости

## 📚 Дополнительная информация

### Миграция с V1 на V2
Compose V1 прекратил получать обновления в июле 2023 года и больше не включается в новые релизы Docker Desktop. Compose V2 теперь интегрирован во все текущие версии Docker Desktop.

### Установка Docker Compose V2
```bash
# Для Ubuntu/Debian
sudo apt update
sudo apt install docker-compose-plugin

# Проверка установки
docker compose version
```

### Локальная разработка
Для локальной разработки используйте:
```bash
# Создайте .env файл
cp env.example .env

# Запустите приложение
docker compose up -d

# Проверьте статус
docker compose ps

# Остановите приложение
docker compose down
```

## ✅ Результат
- ✅ CI/CD pipeline теперь работает с обеими версиями Docker Compose
- ✅ Автоматическое определение доступного синтаксиса
- ✅ Улучшенная диагностика и логирование
- ✅ Обратная совместимость обеспечена
- ✅ Документация создана для команды

---

**Ссылки:**
- [Docker Community Forums - Command not found](https://forums.docker.com/t/command-not-found-when-i-try-to-run-docker-compose/97183)
- [KodeKloud - Docker Compose Command Not Found](https://kodekloud.com/blog/docker-compose-command-not-found/) 