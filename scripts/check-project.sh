#!/bin/sh
# Перевіряє compose.yaml проєкту на сумісність з docker-local-hosting.
# Валідує наявність необхідних Traefik-лейблів та мережі.
# Використання: ./scripts/check-project.sh <шлях_до_проєкту>

set -Eeuo pipefail

project_path="${1:-}"
if [ -z "$project_path" ]; then
    echo "Використання: $0 <шлях_до_проєкту>" >&2
    exit 1
fi

compose_file="$project_path/compose.yaml"
[ ! -f "$compose_file" ] && compose_file="$project_path/docker-compose.yml"
if [ ! -f "$compose_file" ]; then
    echo "[ПОМИЛКА] У $project_path не знайдено compose-файл." >&2
    exit 1
fi

echo "Перевірка проєкту: $project_path"
echo "Файл: $compose_file"

grep -q '^services:' "$compose_file" && echo "[OK] services присутня." || { echo "[ПОМИЛКА] Немає services." >&2; exit 1; }

net_count=$(grep -cE '\$\{LOCAL_HOSTING_NETWORK' "$compose_file" || true)
[ "$net_count" -ge 1 ] && echo "[OK] Сервіси підключені до LOCAL_HOSTING_NETWORK." || echo "[УВАГА] Не знайдено LOCAL_HOSTING_NETWORK."

grep -q 'traefik.enable=true' "$compose_file" && echo "[OK] traefik.enable=true." || echo "[УВАГА] Не знайдено."
grep -q 'traefik.http.routers' "$compose_file" && echo "[OK] traefik.http.routers." || echo "[УВАГА] Не знайдено."
grep -q 'entrypoints=websecure' "$compose_file" && echo "[OK] entrypoints=websecure." || echo "[УВАГА] Не знайдено."
grep -q '\.tls=true' "$compose_file" && echo "[OK] tls=true." || echo "[УВАГА] Не знайдено."

echo ""
echo "=== Порт ==="
if grep -q 'loadbalancer.server.port' "$compose_file"; then
    echo "[OK] Явний server.port."
elif grep -q 'expose:' "$compose_file"; then
    echo "[OK] Expose знайдено."
else
    echo "[УВАГА] Немає server.port та expose."
fi

echo ""
echo "=== Мережа ==="
grep -q 'external: true' "$compose_file" && echo "[OK] external: true." || echo "[УВАГА] Немає external: true."

echo ""
echo "Перевірка завершена."
