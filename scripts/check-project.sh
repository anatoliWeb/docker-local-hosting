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

root_dir="$(cd "$(dirname "$0")/.." && pwd)"

compose_file="$project_path/compose.yaml"
if [ ! -f "$compose_file" ]; then
    compose_file="$project_path/docker-compose.yml"
fi
if [ ! -f "$compose_file" ]; then
    echo "[ПОМИЛКА] У $project_path не знайдено compose.yaml або docker-compose.yml" >&2
    exit 1
fi

echo "Перевірка проєкту: $project_path"
echo "Файл: $compose_file"

# 1. Наявність services
if ! grep -q '^services:' "$compose_file"; then
    echo "[ПОМИЛКА] Немає секції services." >&2
    exit 1
fi
echo "[OK] Секція services присутня."

# 2. Мережа
total=$(grep -cE '^\s+\w+:' "$compose_file" || true)
network_count=$(grep -cE '\$\{LOCAL_HOSTING_NETWORK:-local-hosting\}' "$compose_file" || true)
if [ "$network_count" -ge 1 ]; then
    echo "[OK] Сервіси підключені до LOCAL_HOSTING_NETWORK."
else
    echo "[УВАГА] Не знайдено LOCAL_HOSTING_NETWORK. Додайте мережу до сервісів."
fi

# 3. Traefik-лейбли
if grep -q 'traefik.enable=true' "$compose_file"; then
    echo "[OK] Знайдено traefik.enable=true."
else
    echo "[УВАГА] Не знайдено traefik.enable=true. Traefik не зможе маршрутизувати."
fi

if grep -q 'traefik.http.routers' "$compose_file"; then
    echo "[OK] Знайдено traefik.http.routers."
else
    echo "[УВАГА] Не знайдено traefik.http.routers. Додайте правило маршрутизації."
fi

if grep -q 'entrypoints=websecure' "$compose_file"; then
    echo "[OK] Знайдено entrypoints=websecure."
else
    echo "[УВАГА] Не знайдено entrypoints=websecure."
fi

if grep -q '\.tls=true' "$compose_file"; then
    echo "[OK] Знайдено tls=true."
else
    echo "[УВАГА] Не знайдено tls=true. HTTPS не буде працювати."
fi

echo ""
echo "Перевірка завершена."
