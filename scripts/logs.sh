#!/bin/sh
# Показує логи docker-local-hosting.
# Використання:
#   ./scripts/logs.sh                    # останні 50 рядків усіх сервісів
#   ./scripts/logs.sh traefik            # останні 50 рядків traefik
#   ./scripts/logs.sh traefik 100        # останні 100 рядків traefik
#   ./scripts/logs.sh -f                 # стежити за всіма

set -Eeuo pipefail

root_dir="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root_dir"

service="${1:-}"
lines="${2:-50}"
follow=""

if [ "$service" = "-f" ]; then
    follow="-f"
    service=""
fi

docker compose logs --tail="$lines" $follow $service
