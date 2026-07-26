#!/bin/sh
# Виводить рядки для /etc/hosts або C:\Windows\System32\drivers\etc\hosts
# Читає домени з .env або аргументів командного рядка.
# Використання:
#   ./scripts/show-hosts-entry.sh
#   ./scripts/show-hosts-entry.sh myapp.home.arpa
#   ./scripts/show-hosts-entry.sh app1.home.arpa app2.home.arpa

set -Eeuo pipefail

root_dir="$(cd "$(dirname "$0")/.." && pwd)"

domains=()

if [ $# -gt 0 ]; then
    domains=("$@")
else
    if [ -f "$root_dir/.env" ]; then
        . "$root_dir/.env"
        [ -n "${TRAEFIK_DASHBOARD_HOST:-}" ] && domains+=("$TRAEFIK_DASHBOARD_HOST")
        [ -n "${DEMO_HOST:-}" ] && domains+=("$DEMO_HOST")
    fi
    if [ ${#domains[@]} -eq 0 ]; then
        domains=("traefik.home.arpa" "demo.home.arpa")
    fi
fi

echo "# Додайте наступні рядки у файл hosts:"
echo "# Windows: C:\\Windows\\System32\\drivers\\etc\\hosts"
echo "# Linux/macOS: /etc/hosts"
echo ""

for d in "${domains[@]}"; do
    echo "127.0.0.1	$d"
done

echo ""
echo "Для застосування на Linux:"
echo "  sudo sh -c 'for d in ${domains[*]}; do echo \"127.0.0.1 \$d\" >> /etc/hosts; done'"
