#!/bin/sh
# Генерує TLS-сертифікати для локальних доменів через mkcert.
# Читає TLS_CERT_FILE, TLS_KEY_FILE, MKCERT_DOMAINS із .env.
# Якщо сертифікати існують і дійсні — пропускає.
# Створює бекап старих сертифікатів.

set -Eeuo pipefail

root_dir="$(cd "$(dirname "$0")/.." && pwd)"

if [ ! -f "$root_dir/.env" ]; then
    echo "[ПОМИЛКА] .env не знайдено." >&2
    exit 1
fi

. "$root_dir/.env"

cert_rel="${TLS_CERT_FILE:-./certs/home.arpa.pem}"
key_rel="${TLS_KEY_FILE:-./certs/home.arpa-key.pem}"
domains="${MKCERT_DOMAINS:-home.arpa *.home.arpa}"

cert_path="$root_dir/${cert_rel#./}"
key_path="$root_dir/${key_rel#./}"
certs_dir="$(dirname "$cert_path")"

mkdir -p "$certs_dir"

# Перевірка mkcert
if ! command -v mkcert >/dev/null 2>&1; then
    echo "[ПОМИЛКА] mkcert не знайдено. Встановіть: https://github.com/FiloSottile/mkcert" >&2
    exit 1
fi

# Перевірка існуючих сертифікатів
skip=false
if [ -f "$cert_path" ] && [ -f "$key_path" ]; then
    if [ -s "$cert_path" ] && [ -s "$key_path" ]; then
        if command -v openssl >/dev/null 2>&1; then
            expiry=$(openssl x509 -enddate -noout -in "$cert_path" 2>/dev/null | cut -d= -f2)
            if [ -n "$expiry" ]; then
                expiry_epoch=$(date -d "$expiry" +%s 2>/dev/null || echo 0)
                now_epoch=$(date +%s)
                days_left=$(( (expiry_epoch - now_epoch) / 86400 ))
                if [ "$days_left" -gt 30 ]; then
                    echo "[OK] Сертифікати дійсні ще $days_left днів, пропускаю генерацію."
                    skip=true
                elif [ "$days_left" -gt 0 ]; then
                    echo "[УВАГА] Сертифікати скоро прострочаться ($days_left днів)."
                else
                    echo "[УВАГА] Сертифікати прострочено."
                fi
            fi
        fi
    fi
fi

if [ "$skip" = true ]; then
    exit 0
fi

# Бекап старих сертифікатів
if [ -f "$cert_path" ] || [ -f "$key_path" ]; then
    backup_dir="$certs_dir/backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$backup_dir"
    [ -f "$cert_path" ] && mv "$cert_path" "$backup_dir/"
    [ -f "$key_path" ] && mv "$key_path" "$backup_dir/"
    echo "[INFO] Старі сертифікати переміщено до $backup_dir"
fi

# На Linux mkcert не встановлює CA автоматично
if ! mkcert -CAROOT >/dev/null 2>&1; then
    echo "[INFO] Ініціалізація mkcert CA..."
    mkcert -install
fi

echo "Генерую сертифікати для: $domains"
# shellcheck disable=SC2086
mkcert -cert-file "$cert_path" -key-file "$key_path" $domains

echo "[OK] Сертифікати створено:"
echo "  Сертифікат: $cert_path"
echo "  Ключ:       $key_path"
