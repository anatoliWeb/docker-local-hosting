#!/bin/sh
# Показує список зовнішніх сервісів, зареєстрованих у Traefik.
# Використання: ./scripts/list-external-services.sh

set -Eeuo pipefail

root_dir="$(cd "$(dirname "$0")/.." && pwd)"
registry_file="$root_dir/config/traefik/dynamic/external-services.yaml"

[ ! -f "$registry_file" ] && { echo "Зовнішні сервіси не знайдено."; exit 0; }

echo "Зовнішні сервіси Traefik:"
echo ""

awk '
/^    [a-zA-Z][a-zA-Z0-9_-]*:$/ {
    if (in_routers) { name = $1; gsub(/:$/, "", name); domain = "" }
    if (in_services) { svc_name = $1; gsub(/:$/, "", svc_name) }
}
/^  routers:/ { in_routers = 1; in_services = 0 }
/^  services:/ { in_services = 1; in_routers = 0 }
in_routers && /rule:/ {
    match($0, /`([^`]+)`/, arr)
    domain = arr[1]
    if (name && domain) {
        printf "  %s\n    Домен:   https://%s\n", name, domain
    }
}
in_services && /url:/ {
    match($0, /"([^"]+)"/, arr)
    url = arr[1]
    if (svc_name && url) {
        printf "    Бекенд:  %s\n\n", url
    }
}
' "$registry_file"

count=$(grep -c '^    [a-zA-Z][a-zA-Z0-9_-]*:$' "$registry_file")
echo "Усього: $((count / 2))"
