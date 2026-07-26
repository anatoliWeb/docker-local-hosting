#!/bin/sh
# Показує статус сервісів docker-local-hosting.

set -Eeuo pipefail

root_dir="$(cd "$(dirname "$0")/.." && pwd)"

echo "================================================"
echo "  Docker Local Hosting — статус"
echo "================================================"
echo ""

echo "=== Docker Compose ==="
cd "$root_dir"
docker compose ps 2>&1

echo ""
echo "=== Сертифікати ==="
cert_file="$root_dir/certs/home.arpa.pem"
key_file="$root_dir/certs/home.arpa-key.pem"
if [ -f "$cert_file" ]; then
    size=$(stat -c%s "$cert_file" 2>/dev/null || stat -f%z "$cert_file" 2>/dev/null || echo "?")
    echo "Сертифікат: $size байт"
else
    echo "Сертифікат: НЕ ЗНАЙДЕНО"
fi
if [ -f "$key_file" ]; then
    size=$(stat -c%s "$key_file" 2>/dev/null || stat -f%z "$key_file" 2>/dev/null || echo "?")
    echo "Ключ: $size байт"
else
    echo "Ключ: НЕ ЗНАЙДЕНО"
fi
