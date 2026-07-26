#!/bin/sh
# Налаштовує та перевіряє середовище docker-local-hosting.
# Перевіряє Git, Docker, .env, мережу, сертифікати.
# За потреби автоматично створює сертифікати та мережу.

set -Eeuo pipefail

root_dir="$(cd "$(dirname "$0")/.." && pwd)"

echo "========================================"
echo "  Docker Local Hosting — налаштування"
echo "========================================"

# 1. Git
echo ""
echo "==> 1. Перевірка Git"
if command -v git >/dev/null 2>&1; then echo "[OK] Git знайдено."
else echo "[УВАГА] Git не знайдено."; fi

# 2. Docker
echo ""
echo "==> 2. Перевірка Docker"
if command -v docker >/dev/null 2>&1; then echo "[OK] Docker: $(docker --version)"
else echo "[ПОМИЛКА] Docker не знайдено."; exit 1; fi

# 3. Docker daemon
echo ""
echo "==> 3. Перевірка Docker daemon"
if docker info >/dev/null 2>&1; then echo "[OK] Docker daemon працює."
else echo "[ПОМИЛКА] Docker daemon недоступний."; exit 1; fi

# 4. Docker Compose
echo ""
echo "==> 4. Перевірка Docker Compose"
if docker compose version >/dev/null 2>&1; then echo "[OK] Compose: $(docker compose version)"
else echo "[ПОМИЛКА] Docker Compose не знайдено."; exit 1; fi

# 5. .env
echo ""
echo "==> 5. Перевірка .env"
if [ -f "$root_dir/.env" ]; then
    echo "[OK] Файл .env існує."
    if grep -q '^TRAEFIK_BASIC_AUTH=$' "$root_dir/.env"; then
        echo "[УВАГА] TRAEFIK_BASIC_AUTH порожній. Dashboard буде недоступний."
    fi
else
    echo "[УВАГА] Файл .env відсутній."
    if [ -f "$root_dir/.env.example" ]; then
        echo "  Створюю .env із .env.example..."
        cp "$root_dir/.env.example" "$root_dir/.env"
        echo "[OK] Створено."
        echo "[УВАГА] Відредагуйте .env, особливо TRAEFIK_BASIC_AUTH."
    else
        echo "[ПОМИЛКА] .env.example відсутній."
        exit 1
    fi
fi

# Завантаження змінних
[ -f "$root_dir/.env" ] && . "$root_dir/.env"
network_name="${LOCAL_HOSTING_NETWORK:-local-hosting}"
cert_file="${TLS_CERT_FILE:-./certs/home.arpa.pem}"
key_file="${TLS_KEY_FILE:-./certs/home.arpa-key.pem}"
auto_certs="${AUTO_GENERATE_CERTS:-true}"
auto_network="${AUTO_CREATE_NETWORK:-true}"

# 6. Мережа
echo ""
echo "==> 6. Перевірка мережі $network_name"
if docker network ls --format "{{.Name}}" | grep -q "^${network_name}$"; then
    echo "[OK] Мережа $network_name існує."
elif [ "$auto_network" = "true" ]; then
    echo "[УВАГА] Мережа $network_name відсутня. Створюю..."
    docker network create "$network_name" --driver bridge --attachable
    echo "[OK] Мережу $network_name створено."
else
    echo "[УВАГА] Мережа $network_name відсутня. Створіть вручну:"
    echo "  docker network create $network_name --driver bridge --attachable"
fi

# 7. Сертифікати
echo ""
echo "==> 7. Перевірка сертифікатів"
cert_path="$root_dir/${cert_file#./}"
key_path="$root_dir/${key_file#./}"

if [ -f "$cert_path" ] && [ -f "$key_path" ]; then
    echo "[OK] Сертифікати знайдено."
    if [ ! -s "$cert_path" ]; then echo "[ПОМИЛКА] Сертифікат порожній."; exit 1; fi
    if [ ! -s "$key_path" ]; then echo "[ПОМИЛКА] Ключ порожній."; exit 1; fi
    if command -v openssl >/dev/null 2>&1; then
        expiry=$(openssl x509 -enddate -noout -in "$cert_path" 2>/dev/null | cut -d= -f2)
        if [ -n "$expiry" ]; then
            expiry_epoch=$(date -d "$expiry" +%s 2>/dev/null || echo 0)
            now_epoch=$(date +%s)
            days_left=$(( (expiry_epoch - now_epoch) / 86400 ))
            if [ "$days_left" -lt 0 ]; then echo "[УВАГА] Сертифікат прострочено."
            elif [ "$days_left" -lt 30 ]; then echo "[УВАГА] Сертифікат скоро прострочиться (${days_left} днів)."
            else echo "[OK] Сертифікат дійсний ще $days_left днів."; fi
        fi
    fi
else
    if [ "$auto_certs" = "true" ]; then
        echo "[УВАГА] Сертифікати не знайдено. Запускаю генерацію..."
        "$root_dir/scripts/generate-certs.sh"
        echo "[OK] Сертифікати згенеровано."
    else
        echo "[УВАГА] Сертифікати не знайдено. Згенеруйте вручну:"
        echo "  ./scripts/generate-certs.sh"
    fi
fi

# 8. Валідація Compose
echo ""
echo "==> 8. Валідація Docker Compose"
if docker compose config >/dev/null 2>&1; then
    echo "[OK] Конфігурація валідна."
else
    echo "[ПОМИЛКА] Помилка валідації:"
    docker compose config
    exit 1
fi

# Підсумок
echo ""
echo "==> Підсумок"
echo "[OK] Налаштування завершено."
echo ""
echo "Запустіть проєкт:"
echo "  docker compose up -d"
echo ""
echo "Перед запуском:"
echo "  1. Додайте записи у /etc/hosts"
echo "  2. Переконайтеся, що mkcert CA встановлено: mkcert -install"
echo "  3. Відкрийте https://demo.home.arpa"
