# Trivy Security Scan Fix

## Проблема
При выполнении CI/CD pipeline возникала ошибка:
```
Error: Resource not accessible by integration - https://docs.github.com/rest
```

Эта ошибка происходила при попытке загрузить результаты Trivy сканирования в GitHub Security tab.

## Причина
GitHub Actions требует специальных разрешений для загрузки SARIF файлов в Security tab. По умолчанию workflow не имеет права `security-events: write`.

## Решение

### 1. Добавлены необходимые разрешения
```yaml
permissions:
  contents: read
  security-events: write  # Для загрузки SARIF результатов
  actions: read
```

### 2. Улучшена обработка ошибок
```yaml
- name: Upload Trivy scan results to GitHub Security
  uses: github/codeql-action/upload-sarif@v3
  if: always()
  with:
    sarif_file: 'trivy-results.sarif'
  continue-on-error: true  # Не прерывать pipeline при ошибке
```

### 3. Добавлен fallback механизм
```yaml
- name: Upload Trivy scan results as artifact (fallback)
  uses: actions/upload-artifact@v4
  if: always()
  with:
    name: trivy-scan-results
    path: 'trivy-results.sarif'
    retention-days: 30
```

### 4. Добавлено дублирование в table формате
Для лучшей видимости результатов в логах CI/CD:
```yaml
- name: Run Trivy vulnerability scanner (table format for logs)
  uses: aquasecurity/trivy-action@master
  with:
    image-ref: ${{ env.IMAGE_NAME }}:test
    format: 'table'
  continue-on-error: true
```

### 5. Создан .trivyignore файл
Для управления исключениями уязвимостей (после security review).

## Результат
- ✅ SARIF результаты загружаются в GitHub Security tab
- ✅ Pipeline не прерывается при проблемах с загрузкой
- ✅ Результаты всегда сохраняются как artifacts
- ✅ Улучшена видимость результатов сканирования
- ✅ Добавлена возможность управления исключениями

## Проверка
После применения исправлений:
1. Pipeline должен завершаться успешно
2. Результаты Trivy должны появляться в GitHub Security tab
3. SARIF файлы должны быть доступны как artifacts
4. Логи должны содержать таблицу с найденными уязвимостями 