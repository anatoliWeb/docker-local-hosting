#!/bin/sh
# Зупиняє центральні сервіси без видалення мережі.
# Використовує docker compose stop (не down).
# Для повного видалення: ./scripts/destroy.sh

set -Eeuo pipefail

root_dir="$(cd "$(dirname "$0")/.." && pwd)"

echo "================================================"
echo "  Docker Local Hosting — зупинка"
echo "================================================"
echo ""
echo "Зупинка сервісів (docker compose stop)..."

cd "$root_dir"
docker compose stop

echo ""
echo "[OK] Сервіси зупинено."
echo "[OK] Мережа 'local-hosting' збережена."
echo ""
echo "Запуск: ./scripts/start.sh"
echo "Повне видалення: ./scripts/destroy.sh"
