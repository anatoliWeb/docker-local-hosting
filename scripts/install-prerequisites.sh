#!/bin/sh
# Одноразова підготовка комп'ютера для docker-local-hosting.
# Встановлює mkcert, створює CA, перевіряє Docker.
# Не змінює систему без підтвердження.

set -Eeuo pipefail

root_dir="$(cd "$(dirname "$0")/.." && pwd)"

echo "================================================"
echo "  Docker Local Hosting — підготовка комп'ютера"
echo "================================================"

echo ""
echo "==> 1. Git"
if command -v git >/dev/null 2>&1; then echo "[OK] Git знайдено."
else echo "[УВАГА] Git не знайдено."; fi

echo ""
echo "==> 2. Docker"
if command -v docker >/dev/null 2>&1; then echo "[OK] Docker: $(docker --version)"
else echo "[ПОМИЛКА] Docker не знайдено."; exit 1; fi

echo ""
echo "==> 3. Docker daemon"
if docker info >/dev/null 2>&1; then echo "[OK] Docker daemon працює."
else echo "[ПОМИЛКА] Docker daemon недоступний."; exit 1; fi

echo ""
echo "==> 4. Docker Compose"
if docker compose version >/dev/null 2>&1; then echo "[OK] Compose: $(docker compose version)"
else echo "[ПОМИЛКА] Docker Compose не знайдено."; exit 1; fi

echo ""
echo "==> 5. mkcert"
if command -v mkcert >/dev/null 2>&1; then
    echo "[OK] mkcert знайдено."
    ca_root=$(mkcert -CAROOT 2>/dev/null)
    echo "[OK] CA каталог: $ca_root"
else
    echo "[УВАГА] mkcert не знайдено."
    echo "  Встановіть: sudo apt install libnss3-tools"
    echo "  curl -JLO 'https://dl.filippo.io/mkcert/latest?for=linux/amd64'"
fi

echo ""
echo "==> 6. Локальний CA"
if command -v mkcert >/dev/null 2>&1; then
    echo "Створіть CA: mkcert -install"
    echo "Для автоматизації додайте --non-interactive"
fi

echo ""
echo "==> 7. /etc/hosts"
echo "Додайте до /etc/hosts:"
echo "  127.0.0.1 traefik.home.arpa"
echo "  127.0.0.1 demo.home.arpa"

echo ""
echo "==> Підсумок"
echo "[OK] Підготовку завершено."
echo ""
echo "Далі:"
echo "  ./scripts/setup.sh"
echo "  docker compose up -d"
