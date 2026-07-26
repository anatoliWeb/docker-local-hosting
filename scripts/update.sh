#!/bin/sh
# Оновлює образи docker-local-hosting до зафіксованих версій.
# Pull актуальні образи, recreate сервіси.

set -Eeuo pipefail

root_dir="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root_dir"

echo "================================================"
echo "  Docker Local Hosting — оновлення"
echo "================================================"

echo ""
echo "Pull нових образів..."
docker compose pull

echo ""
echo "Зміни:"
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.Size}}"

echo ""
echo "Перезапустіть: docker compose up -d --force-recreate"
