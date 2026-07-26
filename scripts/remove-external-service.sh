#!/bin/sh
# Видаляє зовнішній сервіс з Traefik File Provider.
# Після видалення надсилає SIGHUP Traefik для перезавантаження.
# Використання: ./scripts/remove-external-service.sh -Name camera

set -Eeuo pipefail

usage() { echo "Використання: $0 -Name NAME" >&2; exit 1; }

Name=""
while [ $# -gt 0 ]; do
    case "$1" in
        -Name) Name="$2"; shift 2 ;;
        *) usage ;;
    esac
done
[ -z "$Name" ] && usage

root_dir="$(cd "$(dirname "$0")/.." && pwd)"
registry_file="$root_dir/config/traefik/dynamic/external-services.yaml"

[ ! -f "$registry_file" ] && { echo "[УВАГА] Registry-файл не знайдено." >&2; exit 0; }

if ! grep -q "^    ${Name}:" "$registry_file"; then
    echo "[УВАГА] Сервіс '$Name' не знайдено." >&2
    exit 0
fi

echo "Видалити сервіс '$Name'? (Y/N)"
read -r response
[ "$response" != "Y" ] && [ "$response" != "y" ] && { echo "Скасовано."; exit 0; }

awk -v name="$Name" '
BEGIN { in_routers = 0; in_services = 0; skip = 0 }
/^http:/ { print; next }
/^  routers:/ { in_routers = 1; in_services = 0; print; next }
/^  services:/ { in_services = 1; in_routers = 0; print; next }
in_routers && /^    [a-zA-Z]/ {
    svc = $1; sub(/:$/, "", svc)
    skip = (svc == name)
    if (!skip) print
    next
}
in_routers && !skip { print; next }
in_services && /^    [a-zA-Z]/ {
    svc = $1; sub(/:$/, "", svc)
    skip = (svc == name)
    if (!skip) print
    next
}
in_services && !skip { print; next }
!in_routers && !in_services { print }
' "$registry_file" > "${registry_file}.tmp"

mv "${registry_file}.tmp" "$registry_file"
echo "[OK] Сервіс '$Name' видалено."
echo ""
echo "Перезавантаження конфігурації Traefik..."
docker compose kill -s HUP traefik 2>/dev/null && echo "[OK] Traefik перезавантажено (SIGHUP)." || echo "[УВАГА] Не вдалося відправити SIGHUP."
