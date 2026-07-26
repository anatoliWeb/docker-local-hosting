#!/bin/sh
# Додає зовнішній сервіс (не Docker) до Traefik через File Provider.
# Оновлює config/traefik/dynamic/external-services.yaml.
# Валідує URL: відхиляє 127.0.0.1 та localhost.
# Використання: ./scripts/add-external-service.sh -Name camera -Domain camera.home.arpa -Url http://192.168.1.50:9000

set -Eeuo pipefail

usage() { echo "Використання: $0 -Name NAME -Domain DOMAIN -Url URL" >&2; exit 1; }

Name=""; Domain=""; Url=""
while [ $# -gt 0 ]; do
    case "$1" in
        -Name) Name="$2"; shift 2 ;;
        -Domain) Domain="$2"; shift 2 ;;
        -Url) Url="$2"; shift 2 ;;
        *) usage ;;
    esac
done

[ -z "$Name" ] || [ -z "$Domain" ] || [ -z "$Url" ] && usage

root_dir="$(cd "$(dirname "$0")/.." && pwd)"
dynamic_dir="$root_dir/config/traefik/dynamic"
registry_file="$dynamic_dir/external-services.yaml"

mkdir -p "$dynamic_dir"
[ -d "$dynamic_dir/services" ] && rm -rf "$dynamic_dir/services"

# URL validation
url_scheme=$(echo "$Url" | sed -n 's|^\([a-z][a-z]*\)://.*|\1|p')
url_host=$(echo "$Url" | sed -n 's|^[a-z][a-z]*://\([^:/]*\).*|\1|p')
[ -z "$url_scheme" ] && { echo "[ПОМИЛКА] Некоректний URL: $Url" >&2; exit 1; }
[ "$url_scheme" != "http" ] && [ "$url_scheme" != "https" ] && { echo "[ПОМИЛКА] Схема URL має бути http або https." >&2; exit 1; }
[ "$url_host" = "127.0.0.1" ] || [ "$url_host" = "localhost" ] && {
    echo "[ПОМИЛКА] 127.0.0.1 та localhost з Traefik container означають сам контейнер." >&2
    echo "  Для хоста використовуйте: http://host.docker.internal:9000" >&2
    echo "  Для LAN пристрою: http://192.168.1.50:9000" >&2
    exit 1
}

# Build service entry
entry=$(cat <<SVC
    ${Name}:
      rule: "Host(\`${Domain}\`)"
      entrypoints:
        - websecure
      service: ${Name}
      tls: true

  services:
    ${Name}:
      loadBalancer:
        servers:
          - url: "${Url}"
        passHostHeader: true
SVC
)

# Read existing, strip old entry, append new
if [ -f "$registry_file" ]; then
    awk -v name="$Name" -v entry="$entry" '
    BEGIN { in_block = 0; in_routers = 0; in_services = 0; skip = 0; printed = 0 }
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
    END {
        if (!printed) {
            print entry
        }
    }
    ' "$registry_file" > "${registry_file}.tmp"
else
    cat > "${registry_file}.tmp" <<EOF
# External services registry
# Auto-generated. Do not edit manually.
# Use: ./scripts/add-external-service.sh ./scripts/remove-external-service.sh

http:
  routers:
$(echo "$entry" | sed '1s/^/    /')
EOF
fi

mv "${registry_file}.tmp" "$registry_file"
echo "[OK] Оновлено $registry_file"
echo "Сервіс $Name доступний за адресою https://$Domain"
echo ""
echo "Перезавантаження конфігурації Traefik..."
if docker compose kill -s HUP traefik 2>/dev/null; then
    echo "[OK] Traefik перезавантажено (SIGHUP). Без restart."
else
    echo "[УВАГА] Не вдалося відправити SIGHUP. Перезапустіть: docker compose restart traefik"
fi
echo ""
echo "Додайте в hosts:"
echo "  127.0.0.1 $Domain"
