#!/bin/sh
# Повністю видаляє центральні сервіси, мережу та образи.
# НЕ видаляє .env, сертифікати, secrets.
# Вимагає підтвердження.

set -Eeuo pipefail

root_dir="$(cd "$(dirname "$0")/.." && pwd)"

echo "================================================"
echo "  Docker Local Hosting — ПОВНЕ ВИДАЛЕННЯ"
echo "================================================"
echo ""

network_name="local-hosting"
if docker network ls --format "{{.Name}}" | grep -q "^${network_name}$"; then
    connected=$(docker network inspect "$network_name" --format '{{range .Containers}}{{.Name}} {{end}}' 2>/dev/null)
    if [ -n "$connected" ]; then
        echo "[УВАГА] До мережі '$network_name' підключені:"
        for c in $connected; do echo "  - $c"; done
        echo "Після видалення мережі ці контейнери втратять з'єднання."
        echo ""
    fi
fi

echo "Буде видалено:"
echo "  - контейнери (bootstrap, traefik, docker-socket-proxy, demo)"
echo "  - мережу local-hosting"
echo "  - внутрішню мережу traefik-socket"
echo "  - Docker-образи центральних сервісів"
echo ""
echo "Залишиться:"
echo "  - .env"
echo "  - Сертифікати (certs/)"
echo "  - Secrets (secrets/)"
echo ""

printf "Видалити всі центральні сервіси? (Y/N) "
read -r response
[ "$response" != "Y" ] && [ "$response" != "y" ] && { echo "Скасовано."; exit 0; }

echo ""
echo "Видалення..."
cd "$root_dir"
docker compose down --volumes --rmi all

echo ""
echo "[OK] Центральні сервіси видалено."
echo ""
echo "Для повторного налаштування:"
echo "  ./scripts/install-prerequisites.sh"
echo "  ./scripts/generate-dashboard-auth.sh"
echo "  ./scripts/generate-certs.sh"
echo "  ./scripts/start.sh"
