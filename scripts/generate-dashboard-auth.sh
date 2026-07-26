#!/bin/sh
# Створює secrets/traefik-users для Basic Auth Dashboard.
# Використовує Docker httpd:2.4.62-alpine для генерації bcrypt hash.
# Запуск: ./scripts/generate-dashboard-auth.sh

set -Eeuo pipefail

root_dir="$(cd "$(dirname "$0")/.." && pwd)"
secrets_dir="$root_dir/secrets"
mkdir -p "$secrets_dir"

echo "Створення облікових даних для Traefik Dashboard"
echo "Пароль не відображається на екрані."
echo ""

printf "Логін (наприклад, admin): "
read -r username
[ -z "$username" ] && { echo "[ПОМИЛКА] Логін не може бути порожнім." >&2; exit 1; }

printf "Пароль: "
stty -echo
read -r password
stty echo
echo ""
[ -z "$password" ] && { echo "[ПОМИЛКА] Пароль не може бути порожнім." >&2; exit 1; }

printf "Повторіть пароль: "
stty -echo
read -r confirm
stty echo
echo ""
[ "$password" != "$confirm" ] && { echo "[ПОМИЛКА] Паролі не співпадають." >&2; exit 1; }

echo ""
echo "Генерація bcrypt hash через Docker httpd:2.4.62-alpine..."
hash_line=$(docker run --rm httpd:2.4.62-alpine htpasswd -nbB "$username" "$password" 2>&1 | head -1)
if [ $? -ne 0 ]; then
    echo "[ПОМИЛКА] Не вдалося згенерувати hash: $hash_line" >&2
    exit 1
fi
hash_line=$(echo "$hash_line" | tr -d '\r\n')

users_file="$secrets_dir/traefik-users"
printf '%s' "$hash_line" > "$users_file"
echo "[OK] Файл $users_file створено."

# Перевірка git ignore
if git -C "$root_dir" check-ignore -q "$users_file" 2>/dev/null; then
    echo "[OK] Файл ігнорується Git."
else
    echo "[УВАГА] Файл НЕ ігнорується Git. Перевірте .gitignore."
fi

echo ""
echo "Підсумок:"
echo "  Логін:   $username"
echo "  Файл:    $users_file (ігнорується Git)"
echo ""
echo "Dashboard буде доступний за адресою https://traefik.home.arpa/dashboard/"
echo "Перезапустіть Traefik: docker compose restart traefik"
