# Environment Variables Security Guide

## 🔒 Защита чувствительных данных

Этот документ объясняет, как правильно работать с переменными окружения и защищать чувствительную информацию в проекте.

## ⚠️ Важные принципы безопасности

### 1. Никогда не коммитьте .env файлы в Git

```bash
# ❌ НИКОГДА НЕ ДЕЛАЙТЕ ТАК:
git add .env
git commit -m "Add environment variables"
```

### 2. Всегда используйте .gitignore

Убедитесь, что `.env` файлы исключены из репозитория:

```gitignore
# Environment files
.env
.env.local
.env.*.local
```

### 3. Используйте env.example как шаблон

```bash
# ✅ Правильный способ:
cp env.example .env
# Затем отредактируйте .env с реальными значениями
```

## 📁 Структура файлов

```
project/
├── .env                 # ❌ НЕ в Git (содержит реальные секреты)
├── env.example          # ✅ В Git (только шаблон)
├── .gitignore          # ✅ В Git (исключает .env)
└── ...
```

## 🛠️ Настройка проекта

### Для разработчиков

1. **Клонируйте репозиторий:**
   ```bash
   git clone <repository-url>
   cd devops-cicd-kubernetes-gitops
   ```

2. **Создайте .env файл:**
   ```bash
   cp env.example .env
   ```

3. **Заполните реальными значениями:**
   ```bash
   # Отредактируйте .env файл
   nano .env
   ```

### Для CI/CD

В GitHub Actions используется автоматическое создание `.env`:

```yaml
- name: Create test environment file
  run: |
    cp env.example .env
    echo "METRICS_USER=testuser" >> .env
    echo "METRICS_PASS=testpass123" >> .env
```

## 🔐 Переменные окружения в проекте

### Обязательные переменные

| Переменная | Описание | Пример |
|------------|----------|---------|
| `METRICS_USER` | Пользователь для доступа к метрикам | `admin` |
| `METRICS_PASS` | Пароль для доступа к метрикам | `secure_password_123` |
| `PROMETHEUS_MULTIPROC_DIR` | Директория для Prometheus | `/tmp/prometheus` |

### Опциональные переменные

| Переменная | Описание | По умолчанию |
|------------|----------|--------------|
| `DEBUG` | Режим отладки | `false` |
| `HOST` | Хост приложения | `0.0.0.0` |
| `PORT` | Порт приложения | `8080` |
| `LOG_LEVEL` | Уровень логирования | `INFO` |

## 🚨 Что делать если .env попал в Git

### 1. Немедленные действия

```bash
# Удалить из отслеживания Git
git rm --cached .env

# Добавить в .gitignore (если ещё не добавлено)
echo ".env" >> .gitignore

# Коммитнуть изменения
git add .gitignore
git commit -m "Remove .env from tracking and add to .gitignore"
```

### 2. Смена всех секретов

- 🔄 Смените все пароли и API ключи
- 🔄 Обновите токены доступа
- 🔄 Пересоздайте секретные ключи

### 3. Очистка истории Git (опционально)

⚠️ **Внимание:** Это сложная операция, используйте с осторожностью!

```bash
# Удаление файла из всей истории Git
git filter-branch --force --index-filter \
  'git rm --cached --ignore-unmatch .env' \
  --prune-empty --tag-name-filter cat -- --all
```

## 📚 Лучшие практики

### ✅ Делайте

- Используйте `env.example` как шаблон
- Документируйте все переменные
- Используйте сильные пароли
- Регулярно ротируйте секреты
- Используйте разные секреты для разных сред

### ❌ Не делайте

- Не коммитьте `.env` файлы
- Не используйте слабые пароли
- Не делитесь секретами в чатах/email
- Не используйте одинаковые секреты везде
- Не игнорируйте предупреждения безопасности

## 🔗 Полезные ссылки

- [.Env, .gitignore, and protecting API keys](https://dev.to/eprenzlin/env-gitignore-and-protecting-api-keys-2b9l)
- [Should I add .env to .gitignore?](https://salferrarello.com/add-env-to-gitignore/)
- [GitHub: Removing sensitive data](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository)

## 🆘 Помощь

Если у вас есть вопросы по безопасности или вы случайно закоммитили секреты:

1. Немедленно смените все затронутые секреты
2. Следуйте инструкциям выше
3. Обратитесь к команде безопасности

---

**Помните:** Безопасность - это не одноразовое действие, а постоянный процесс! 🔒 