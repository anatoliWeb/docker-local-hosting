#!/usr/bin/env bash
# Перевіряє готовність системи без внесення змін.

set -Eeuo pipefail

allow_missing_startup_prerequisites=false
if [[ "${1:-}" == "--allow-missing-startup-prerequisites" ]]; then
    allow_missing_startup_prerequisites=true
fi

root_dir="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root_dir"
errors=0
warnings=0

step() { printf '\n==> %s\n' "$1"; }
pass() { printf '  [ГОТОВО] %s\n' "$1"; }
warn() { printf '  [ПОПЕРЕДЖЕННЯ] %s\n' "$1"; warnings=$((warnings + 1)); }
fail() { printf '  [ПОМИЛКА] %s\n' "$1" >&2; errors=$((errors + 1)); }
require_file() {
    if [[ -s "$1" ]]; then pass "$2"; return; fi
    if "$allow_missing_startup_prerequisites"; then warn "$2 відсутній"; else fail "$2 відсутній"; fi
}

echo "================================================"
echo "  Preflight — перевірка готовності"
echo "================================================"

step "1. Файли середовища"
[[ -f .env ]] && pass ".env існує" || fail ".env відсутній. Запустіть ./start.sh, щоб автоматично створити .env."
[[ -f .env.example ]] && pass ".env.example існує" || fail ".env.example відсутній"

step "2. Docker і Compose"
command -v docker >/dev/null 2>&1 && pass "Docker знайдено" || fail "Docker не знайдено"
docker info >/dev/null 2>&1 && pass "Docker daemon працює" || fail "Docker daemon недоступний"
docker compose version >/dev/null 2>&1 && pass "Docker Compose доступний" || fail "Docker Compose недоступний"

step "3. Dashboard і TLS"
require_file "$root_dir/secrets/traefik-users" "secrets/traefik-users"
if command -v mkcert >/dev/null 2>&1; then
    pass "mkcert знайдено"
    ca_root="$(mkcert -CAROOT 2>/dev/null || true)"
    [[ -n "$ca_root" && -f "$ca_root/rootCA.pem" ]] && pass "Локальний CA mkcert встановлено" || fail "Локальний CA mkcert не підтверджено. Виконайте: mkcert -install"
else
    fail "mkcert не знайдено"
fi
require_file "$root_dir/certs/home.arpa.pem" "TLS сертифікат"
require_file "$root_dir/certs/home.arpa-key.pem" "TLS ключ"

step "4. Compose і мережа"
docker compose config >/dev/null && pass "Конфігурація Docker Compose валідна" || fail "Конфігурація Docker Compose невалідна"
network="$(awk -F= '/^LOCAL_HOSTING_NETWORK=/{print $2; exit}' .env 2>/dev/null || true)"
network="${network:-local-hosting}"
docker network inspect "$network" >/dev/null 2>&1 && pass "Мережа $network існує" || warn "Мережа $network буде створена під час запуску"

step "5. Безпека і конфігурація"
for path in .env certs/home.arpa-key.pem secrets/traefik-users; do
    git check-ignore -q -- "$path" && pass "$path ігнорується Git" || fail "$path не ігнорується Git"
done
grep -q 'exposedByDefault: false' config/traefik/traefik.yaml && pass "exposedByDefault=false" || fail "exposedByDefault=false відсутній"
! grep -q 'api.insecure' config/traefik/traefik.yaml && pass "api.insecure не використовується" || fail "api.insecure знайдено"
grep -q 'usersFile: /run/secrets/traefik-users' config/traefik/dynamic/dashboard.yaml && pass "Dashboard використовує usersFile" || fail "Dashboard Basic Auth налаштовано небезпечно"
! sed -n '/^  traefik:/,/^  [a-zA-Z-]*:/p' compose.yaml | grep -q '/var/run/docker.sock' && pass "Traefik не має прямого Docker socket" || fail "Traefik має прямий Docker socket"
grep -q '/var/run/docker.sock:/var/run/docker.sock:ro' compose.yaml && pass "Socket Proxy має read-only socket" || fail "Socket Proxy налаштовано небезпечно"
grep -q './config/traefik/dynamic:/etc/traefik/dynamic:ro' compose.yaml && pass "Dynamic directory змонтовано read-only" || fail "Dynamic directory не змонтовано"

step "6. Версії образів"
if git ls-files '*.yaml' '*.yml' | xargs grep -nE ':latest|stable-alpine' >/dev/null 2>&1; then
    fail "Знайдено неприкріплені версії образів"
else
    pass "У tracked YAML немає :latest або stable-alpine"
fi

step "Підсумок"
if [[ "$errors" -eq 0 ]]; then
    echo "  Система готова до ручного тестування"
else
    echo "  Система НЕ готова до ручного тестування ($errors помилок, $warnings попереджень)" >&2
fi
exit "$errors"
