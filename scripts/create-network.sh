#!/bin/sh
# Створює зовнішню Docker-мережу для docker-local-hosting.
# Читає LOCAL_HOSTING_NETWORK із .env.

set -Eeuo pipefail

root_dir="$(cd "$(dirname "$0")/.." && pwd)"

if [ ! -f "$root_dir/.env" ]; then
    echo "[ПОМИЛКА] .env не знайдено. Скопіюйте .env.example у .env."
    exit 1
fi

. "$root_dir/.env"
network_name="${LOCAL_HOSTING_NETWORK:-local-hosting}"

if docker network ls --format "{{.Name}}" | grep -q "^${network_name}$"; then
    echo "[OK] Мережа '$network_name' вже існує."
    exit 0
fi

echo "Створюю мережу '$network_name'..."
docker network create "$network_name" --driver bridge --attachable
echo "[OK] Мережу '$network_name' створено."
