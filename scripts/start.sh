#!/usr/bin/env bash
# Сумісний запуск для Linux. Windows використовує .\start.ps1.

set -Eeuo pipefail

root_dir="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root_dir"

"$root_dir/scripts/ensure-env.sh"
command -v docker >/dev/null 2>&1 || { echo "[ПОМИЛКА] Docker не знайдено." >&2; exit 1; }
docker info >/dev/null || { echo "[ПОМИЛКА] Docker daemon недоступний." >&2; exit 1; }
docker compose version >/dev/null || { echo "[ПОМИЛКА] Docker Compose недоступний." >&2; exit 1; }

"$root_dir/scripts/preflight.sh" --allow-missing-startup-prerequisites || true

if [[ ! -s "$root_dir/secrets/traefik-users" ]]; then
    echo "[ПОМИЛКА] Не налаштовано Basic Auth. Запустіть: ./scripts/generate-dashboard-auth.sh" >&2
    exit 1
fi
if [[ ! -s "$root_dir/certs/home.arpa.pem" || ! -s "$root_dir/certs/home.arpa-key.pem" ]]; then
    echo "[ПОМИЛКА] TLS-сертифікати відсутні. Встановіть mkcert і запустіть: ./scripts/generate-certs.sh" >&2
    exit 1
fi

docker compose config
docker compose up -d

deadline=$((SECONDS + 90))
while (( SECONDS < deadline )); do
    bootstrap="$(docker inspect -f '{{.State.Status}}:{{.State.ExitCode}}' docker-local-hosting-bootstrap 2>/dev/null || true)"
    traefik="$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' traefik 2>/dev/null || true)"
    demo="$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' docker-local-hosting-demo 2>/dev/null || true)"
    [[ "$bootstrap" == "exited:0" && "$traefik" == "healthy" && "$demo" == "healthy" ]] && break
    [[ "$bootstrap" =~ exited:[1-9] ]] && { echo "[ПОМИЛКА] Bootstrap завершився з помилкою." >&2; exit 1; }
    sleep 3
done

[[ "$bootstrap" == "exited:0" && "$traefik" == "healthy" && "$demo" == "healthy" ]] || { echo "[ПОМИЛКА] Healthcheck не пройдено за 90 секунд." >&2; exit 1; }
docker compose ps
echo "https://demo.home.arpa"
echo "https://traefik.home.arpa/dashboard/"
echo "docs/MANUAL-TESTING-WINDOWS.md"
