#!/usr/bin/env bash
# Створює .env з .env.example лише за його відсутності.

set -Eeuo pipefail

root_dir="$(cd "$(dirname "$0")/.." && pwd)"
env_example="$root_dir/.env.example"
env_file="$root_dir/.env"

if [ ! -f "$env_example" ]; then
    echo "[ПОМИЛКА] Файл .env.example відсутній." >&2
    exit 1
fi

if [ -f "$env_file" ]; then
    echo "Файл .env уже існує"
    exit 0
fi

cp "$env_example" "$env_file"

if ! git -C "$root_dir" check-ignore -q .env; then
    rm -f "$env_file"
    echo "[ПОМИЛКА] .env не ігнорується Git. Перевірте .gitignore." >&2
    exit 1
fi

echo "Створено .env з .env.example"
