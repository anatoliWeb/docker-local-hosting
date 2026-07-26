#!/bin/sh
# Налаштовує та перевіряє середовище docker-local-hosting.
# Перевіряє Git, Docker, .env, мережу, сертифікати та надає інструкції.

set -Eeuo pipefail

root_dir="$(cd "$(dirname "$0")/.." && pwd)"

echo "========================================"
echo "  Docker Local Hosting — налаштування"
echo "========================================"

# 1. Git
echo ""
echo "==> 1. Перевірка Git"
if command -v git >/dev/null 2>&1; then
    echo "[OK] Git знайдено: $(git --version)"
else
    echo "[УВАГА] Git не знайдено."
fi

# 2. Docker
echo ""
echo "==> 2. Перевірка Docker"
if command -v docker >/dev/null 2>&1; then
    echo "[OK] Docker знайдено: $(docker --version)"
else
    echo "[ПОМИЛКА] Docker не знайдено."
    exit 1
fi

# 3. Docker daemon
echo ""
echo "==> 3. Перевірка Docker daemon"
if docker info >/dev/null 2>&1; then
    echo "[OK] Docker daemon працює."
else
    echo "[ПОМИЛКА] Docker daemon недоступний. Запустіть Docker."
    exit 1
fi

# 4. Docker Compose
echo ""
echo "==> 4. Перевірка Docker Compose"
if docker compose version >/dev/null 2>&1; then
    echo "[OK] Docker Compose знайдено: $(docker compose version)"
else
    echo "[ПОМИЛКА] Docker Compose не знайдено."
    exit 1
fi

# 5. .env
echo ""
echo "==> 5. Перевірка .env"
if [ -f "$root_dir/.env" ]; then
    echo "[OK] Файл .env існує."
else
    echo "[УВАГА] Файл .env відсутній."
    if [ -f "$root_dir/.env.example" ]; then
        echo "  Створюю .env із .env.example..."
        cp "$root_dir/.env.example" "$root_dir/.env"
        echo "[OK] Файл .env створено з .env.example."
        echo "  Відредагуйте .env за потреби."
    else
        echo "[ПОМИЛКА] .env.example також відсутній."
        exit 1
    fi
fi

# 6. Мережа local-hosting
echo ""
echo "==> 6. Перевірка мережі local-hosting"
if docker network ls --format "{{.Name}}" | grep -q "^local-hosting$"; then
    echo "[OK] Мережа local-hosting існує."
else
    echo "[УВАГА] Мережа local-hosting відсутня."
    echo "  Створюю мережу local-hosting..."
    docker network create local-hosting --driver bridge --attachable
    echo "[OK] Мережу local-hosting створено."
fi

# 7. Сертифікати
echo ""
echo "==> 7. Перевірка сертифікатів"
if [ -f "$root_dir/certs/home.arpa.pem" ] && [ -f "$root_dir/certs/home.arpa-key.pem" ]; then
    echo "[OK] Сертифікати знайдено."
else
    echo "[УВАГА] Сертифікати не знайдено."
    echo "  Згенеруйте їх командою:"
    echo "    ./scripts/generate-certs.sh"
fi

# 8. Перевірка конфігурації Compose
echo ""
echo "==> 8. Перевірка конфігурації Docker Compose"
if docker compose config >/dev/null 2>&1; then
    echo "[OK] Конфігурація Docker Compose валідна."
else
    echo "[ПОМИЛКА] Помилка валідації конфігурації."
    docker compose config
    exit 1
fi

# Підсумок
echo ""
echo "==> Підсумок"
echo "Налаштування завершено."
echo ""
echo "Запустіть проєкт командою:"
echo "  docker compose up -d"
echo ""
echo "Перед запуском переконайтеся, що:"
echo "  1. Файл /etc/hosts містить записи для доменів"
echo "  2. mkcert CA встановлено: mkcert -install"
echo "  3. Сертифікати згенеровано"
echo ""
echo "Докладніше: README.md"
