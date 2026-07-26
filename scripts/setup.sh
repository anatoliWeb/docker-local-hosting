#!/bin/sh
# Налаштовує та перевіряє середовище docker-local-hosting.
# Перевіряє Git, Docker, .env, мережу, сертифікати.
# Мережа створюється compose автоматично.

set -Eeuo pipefail

root_dir="$(cd "$(dirname "$0")/.." && pwd)"

echo "========================================"
echo "  Docker Local Hosting — налаштування"
echo "========================================"

echo ""
echo "==> 1. Git"
command -v git >/dev/null 2>&1 && echo "[OK] Git знайдено." || echo "[УВАГА] Git не знайдено."

echo ""
echo "==> 2. Docker"
command -v docker >/dev/null 2>&1 && echo "[OK] Docker: $(docker --version)" || { echo "[ПОМИЛКА] Docker не знайдено." >&2; exit 1; }

echo ""
echo "==> 3. Docker daemon"
docker info >/dev/null 2>&1 && echo "[OK] Docker daemon працює." || { echo "[ПОМИЛКА] Docker daemon недоступний." >&2; exit 1; }

echo ""
echo "==> 4. Docker Compose"
docker compose version >/dev/null 2>&1 && echo "[OK] Compose: $(docker compose version)" || { echo "[ПОМИЛКА] Compose не знайдено." >&2; exit 1; }

echo ""
echo "==> 5. .env"
if [ -f "$root_dir/.env" ]; then
    echo "[OK] .env iснує."
else
    echo "[УВАГА] .env вiдсутнiй."
    if [ -f "$root_dir/.env.example" ]; then
        cp "$root_dir/.env.example" "$root_dir/.env"
        echo "[OK] Створено .env iз .env.example."
        echo "[УВАГА] Вiдредагуйте .env за потреби."
    else
        echo "[ПОМИЛКА] .env.example вiдсутнiй." >&2
        exit 1
    fi
fi

. "$root_dir/.env"
network_name="${LOCAL_HOSTING_NETWORK:-local-hosting}"
cert_file="${TLS_CERT_FILE:-./certs/home.arpa.pem}"
key_file="${TLS_KEY_FILE:-./certs/home.arpa-key.pem}"
auto_certs="${AUTO_GENERATE_CERTS:-true}"

echo ""
echo "==> 6. Мережа $network_name"
if docker network ls --format "{{.Name}}" | grep -q "^${network_name}$"; then
    echo "[OK] Мережа $network_name iснує."
else
    echo "[УВАГА] Мережа $network_name буде створена compose."
fi

echo ""
echo "==> 7. Сертифiкати"
cert_path="$root_dir/${cert_file#./}"
key_path="$root_dir/${key_file#./}"

if [ -f "$cert_path" ] && [ -f "$key_path" ] && [ -s "$cert_path" ] && [ -s "$key_path" ]; then
    echo "[OK] Сертифiкати знайдено."
    if command -v openssl >/dev/null 2>&1; then
        expiry=$(openssl x509 -enddate -noout -in "$cert_path" 2>/dev/null | cut -d= -f2)
        if [ -n "$expiry" ]; then
            expiry_epoch=$(date -d "$expiry" +%s 2>/dev/null || echo 0)
            days_left=$(( (expiry_epoch - $(date +%s)) / 86400 ))
            [ "$days_left" -lt 0 ] && echo "[УВАГА] Прострочено."
            [ "$days_left" -lt 30 ] && [ "$days_left" -ge 0 ] && echo "[УВАГА] Скоро (${days_left} дн.)."
            [ "$days_left" -ge 30 ] && echo "[OK] Дiйсний ще $days_left дн."
        fi
    fi
else
    if [ "$auto_certs" = "true" ] && command -v mkcert >/dev/null 2>&1; then
        echo "[УВАГА] Сертифiкати не знайдено. Запускаю генерацiю..."
        "$root_dir/scripts/generate-certs.sh"
    else
        echo "[УВАГА] Сертифiкати не знайдено. Згенеруйте: ./scripts/generate-certs.sh"
    fi
fi

echo ""
echo "==> 8. Валiдацiя Docker Compose"
docker compose config >/dev/null 2>&1 && echo "[OK] Конфiгурацiя валiдна." || { echo "[ПОМИЛКА] Помилка:" >&2; docker compose config >&2; exit 1; }

echo ""
echo "==> Пiдсумок"
echo "[OK] Налаштування завершено."
echo ""
echo "Запустiть проєкт:"
echo "  docker compose up -d"
echo "  ./scripts/start.sh"
