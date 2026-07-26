#!/bin/sh
# Перевіряє готовність системи до ручного тестування.
# Нічого не змінює. Статуси: ГОТОВО, ПОПЕРЕДЖЕННЯ, ПОМИЛКА.
# Використання: ./scripts/preflight.sh

set -Euo pipefail

errors=0
warnings=0

root_dir="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root_dir"

echo "================================================"
echo "  Preflight — перевірка готовності"
echo "================================================"

step() { echo ""; echo "==> $1"; }
pass() { echo "  [ГОТОВО] $1"; }
warn() { echo "  [ПОПЕРЕДЖЕННЯ] $1"; warnings=$((warnings + 1)); }
fail() { echo "  [ПОМИЛКА] $1"; errors=$((errors + 1)); }

# 1. Каталог
step "1. Каталог проєкту"
[ "$(pwd)" = "$root_dir" ] && pass "Робочий каталог: $root_dir" || fail "Неправильний каталог"

# 2. Git
step "2. Git"
command -v git >/dev/null 2>&1 && pass "Git: $(git --version)" || warn "Git не знайдено"

# 3. Docker
step "3. Docker"
command -v docker >/dev/null 2>&1 && pass "Docker: $(docker --version)" || { fail "Docker не знайдено"; exit 1; }

# 4. Docker daemon
step "4. Docker daemon"
docker info >/dev/null 2>&1 && pass "Docker daemon працює" || fail "Docker daemon недоступний"

# 5. Compose
step "5. Docker Compose"
docker compose version >/dev/null 2>&1 && pass "Compose: $(docker compose version)" || fail "Compose не знайдено"

# 6. .env
step "6. Файл .env"
[ -f "$root_dir/.env" ] && pass ".env існує" || warn ".env відсутній"
[ -f "$root_dir/.env.example" ] && pass ".env.example існує" || fail ".env.example відсутній"

# 7. secrets/traefik-users
step "7. Dashboard Basic Auth"
users_file="$root_dir/secrets/traefik-users"
if [ -f "$users_file" ]; then
    [ -s "$users_file" ] && pass "secrets/traefik-users існує" || warn "secrets/traefik-users порожній"
else
    warn "secrets/traefik-users відсутній"
fi

# 8. Сертифікати
step "8. TLS сертифікати"
[ -f "$root_dir/.env" ] && . "$root_dir/.env"
cert_rel="${TLS_CERT_FILE:-./certs/home.arpa.pem}"
key_rel="${TLS_KEY_FILE:-./certs/home.arpa-key.pem}"
cert_path="$root_dir/${cert_rel#./}"
key_path="$root_dir/${key_rel#./}"

if [ -f "$cert_path" ] && [ -f "$key_path" ]; then
    [ -s "$cert_path" ] && [ -s "$key_path" ] && pass "Сертифікати знайдено" || fail "Сертифікати пошкоджено"
    if command -v openssl >/dev/null 2>&1; then
        expiry=$(openssl x509 -enddate -noout -in "$cert_path" 2>/dev/null | cut -d= -f2)
        if [ -n "$expiry" ]; then
            expiry_epoch=$(date -d "$expiry" +%s 2>/dev/null || echo 0)
            days_left=$(( (expiry_epoch - $(date +%s)) / 86400 ))
            [ "$days_left" -lt 0 ] && warn "Сертифікат прострочено"
            [ "$days_left" -lt 30 ] && [ "$days_left" -ge 0 ] && warn "Скоро ($days_left дн.)"
            [ "$days_left" -ge 30 ] && pass "Дійсний ще $days_left дн."
        fi
    fi
else
    warn "Сертифікати не знайдено"
fi

# 9. mkcert
step "9. mkcert"
if command -v mkcert >/dev/null 2>&1; then
    pass "mkcert знайдено: $(command -v mkcert)"
    ca_root=$(mkcert -CAROOT 2>/dev/null)
    [ -f "$ca_root/rootCA.pem" ] && pass "Локальний CA встановлено" || warn "CA не встановлено"
else
    warn "mkcert не знайдено"
fi

# 10. Мережа
step "10. Мережа local-hosting"
docker network ls --format "{{.Name}}" | grep -q "^local-hosting$" && pass "Мережа існує" || warn "Мережа буде створена compose"

# 11. Порти 80/443
step "11. Порти 80/443"
if command -v ss >/dev/null 2>&1; then
    ss -tlnp | grep -q ":80 " && warn "Порт 80 зайнятий" || pass "Порт 80 вільний"
    ss -tlnp | grep -q ":443 " && warn "Порт 443 зайнятий" || pass "Порт 443 вільний"
else
    warn "ss не знайдено, пропускаю перевірку портів"
fi

# 12. Compose config
step "12. Docker Compose config"
docker compose config >/dev/null 2>&1 && pass "Конфігурація валідна" || fail "Помилка конфігурації"

# 13. .gitignore
step "13. .gitignore"
gitignore="$root_dir/.gitignore"
if [ -f "$gitignore" ]; then
    grep -q '^\.env$' "$gitignore" && pass ".env виключено" || fail ".env НЕ виключено"
    grep -q '^secrets/\*$' "$gitignore" && pass "secrets/* виключено" || fail "secrets/* НЕ виключено"
    grep -q '^certs/\*\.pem$' "$gitignore" && pass "certs/*.pem виключено" || fail "certs/*.pem НЕ виключено"
else
    fail ".gitignore відсутній"
fi

# 14. :latest
step "14. Версії образів"
latest=$(find "$root_dir" -name '*.yaml' -o -name '*.yml' 2>/dev/null | xargs grep -l ':latest' 2>/dev/null || true)
stable=$(find "$root_dir" -name '*.yaml' -o -name '*.yml' 2>/dev/null | xargs grep -l 'stable-alpine' 2>/dev/null || true)
[ -z "$latest" ] && pass "Немає :latest образів" || { fail "Знайдено :latest"; echo "$latest"; }
[ -z "$stable" ] && pass "Немає stable-alpine образів" || { fail "Знайдено stable-alpine"; }

# 15. api.insecure
step "15. api.insecure"
grep -q 'api.insecure' "$root_dir/config/traefik/traefik.yaml" && fail "api.insecure знайдено" || pass "api.insecure не використовується"

# 16. Docker socket
step "16. Docker socket"
grep -q 'traefik.*/var/run/docker.sock' "$root_dir/compose.yaml" && fail "Traefik має прямий socket" || pass "Traefik без прямого socket"

# 17. Dashboard config
step "17. Dashboard конфігурація"
dashboard="$root_dir/config/traefik/dynamic/dashboard.yaml"
if [ -f "$dashboard" ]; then
    grep -q 'usersFile:' "$dashboard" && pass "Використовується usersFile" || warn "Можливий hardcoded hash"
else
    fail "dashboard.yaml відсутній"
fi

# Підсумок
step "Підсумок"
echo ""
if [ "$errors" -eq 0 ] && [ "$warnings" -eq 0 ]; then
    echo "  Система готова до ручного тестування"
elif [ "$errors" -eq 0 ]; then
    echo "  Система готова до ручного тестування ($warnings попереджень)"
else
    echo "  Система НЕ готова до ручного тестування ($errors помилок, $warnings попереджень)"
fi
exit "$errors"
