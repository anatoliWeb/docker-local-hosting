#!/bin/sh
# Рекомендований запуск docker-local-hosting.
# Перевіряє оточення, .env, сертифікати, запускає docker compose up -d.

set -Eeuo pipefail

root_dir="$(cd "$(dirname "$0")/.." && pwd)"

echo "================================================"
echo "  Docker Local Hosting — запуск"
echo "================================================"

echo ""
echo "==> 1. Docker"
if ! docker info >/dev/null 2>&1; then
    echo "[ПОМИЛКА] Docker daemon недоступний." >&2
    exit 1
fi
echo "[OK] Docker daemon працює."

echo ""
echo "==> 2. .env"
if [ ! -f "$root_dir/.env" ]; then
    if [ -f "$root_dir/.env.example" ]; then
        cp "$root_dir/.env.example" "$root_dir/.env"
        echo "[OK] Створено .env iз .env.example."
        echo "[УВАГА] Відредагуйте .env за потреби."
    else
        echo "[ПОМИЛКА] .env.example відсутній." >&2
        exit 1
    fi
else
    echo "[OK] .env iснує."
fi

. "$root_dir/.env"

echo ""
echo "==> 3. Basic Auth"
users_file="$root_dir/secrets/traefik-users"
if [ -f "$users_file" ] && [ -s "$users_file" ]; then
    echo "[OK] Dashboard захищений Basic Auth: secrets/traefik-users."
else
    echo "[УВАГА] secrets/traefik-users вiдсутнiй. Dashboard буде недоступний (401)."
    echo "  Створiть: ./scripts/generate-dashboard-auth.sh"
fi

echo ""
echo "==> 4. mkcert"
if command -v mkcert >/dev/null 2>&1; then
    echo "[OK] mkcert знайдено: $(command -v mkcert)"
else
    echo "[УВАГА] mkcert не знайдено."
fi

echo ""
echo "==> 5. TLS сертифікати"
cert_rel="${TLS_CERT_FILE:-./certs/home.arpa.pem}"
key_rel="${TLS_KEY_FILE:-./certs/home.arpa-key.pem}"
cert_path="$root_dir/${cert_rel#./}"
key_path="$root_dir/${key_rel#./}"

if [ -f "$cert_path" ] && [ -f "$key_path" ] && [ -s "$cert_path" ] && [ -s "$key_path" ]; then
    echo "[OK] Сертифікати знайдено."
else
    echo "[УВАГА] Сертифікати не знайдено або пошкоджено."
    if command -v mkcert >/dev/null 2>&1; then
        echo "  Згенеруйте: ./scripts/generate-certs.sh"
    fi
fi

echo ""
echo "==> 6. Валідація Docker Compose"
if ! docker compose config >/dev/null 2>&1; then
    echo "[ПОМИЛКА] Помилка конфігурації:" >&2
    docker compose config >&2
    exit 1
fi
echo "[OK] Конфігурація валідна."

echo ""
echo "==> 7. Запуск"
docker compose up -d
echo "[OK] docker compose up -d виконано."

echo ""
echo "==> 8. Підсумок"
echo ""
echo "Сайти доступні:"
echo "  https://demo.home.arpa"
echo "  https://traefik.home.arpa (Dashboard)"
echo ""
echo "Команди:"
echo "  ./scripts/status.sh    — статус"
echo "  ./scripts/logs.sh      — логи"
echo "  ./scripts/stop.sh      — зупинка"
echo "  ./scripts/update.sh    — оновлення"
echo "[OK] Запуск завершено."
