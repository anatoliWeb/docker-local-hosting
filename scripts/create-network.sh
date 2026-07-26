#!/bin/sh
# Створює зовнішню Docker-мережу local-hosting, якщо вона ще не існує.
# Idempotent — безпечно запускати багаторазово.

set -Eeuo pipefail

# Перевірка Docker
if ! command -v docker >/dev/null 2>&1; then
    echo "ПОМИЛКА: Docker не знайдено. Встановіть Docker Engine."
    exit 1
fi
echo "Docker знайдено: $(docker --version)"

# Перевірка Docker daemon
if ! docker info >/dev/null 2>&1; then
    echo "ПОМИЛКА: Docker daemon недоступний. Запустіть Docker."
    exit 1
fi
echo "Docker daemon працює."

# Перевірка існування мережі
if docker network ls --format "{{.Name}}" | grep -q "^local-hosting$"; then
    echo "Мережа local-hosting вже існує. Нічого не змінено."
    exit 0
fi

# Створення мережі
echo "Створюю зовнішню Docker-мережу local-hosting..."
docker network create local-hosting --driver bridge --attachable

echo "Мережа local-hosting успішно створена."
echo "Тепер ви можете запустити основний проєкт: docker compose up -d"
