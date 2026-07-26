#!/bin/sh
# Зупиняє центральні сервіси docker-local-hosting.
# Не видаляє спільну мережу local-hosting.

set -Eeuo pipefail

root_dir="$(cd "$(dirname "$0")/.." && pwd)"

echo "================================================"
echo "  Docker Local Hosting — зупинка"
echo "================================================"
echo ""
echo "Зупинка сервісів..."

cd "$root_dir"
docker compose down

net_name="local-hosting"
[ -f .env ] && . .env 2>/dev/null || true
net_name="${LOCAL_HOSTING_NETWORK:-local-hosting}"

if docker network ls --format "{{.Name}}" | grep -q "^${net_name}$"; then
    echo "[OK] Мережа '$net_name' збережена."
else
    echo "[УВАГА] Мережа '$net_name' видалена."
fi

echo "[OK] Сервіси зупинено."
