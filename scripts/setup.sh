#!/usr/bin/env bash
# Налаштовує та перевіряє середовище docker-local-hosting.
# Перевіряє Git, Docker, .env, мережу, сертифікати.
# Мережа створюється compose автоматично.

set -Eeuo pipefail

root_dir="$(cd "$(dirname "$0")/.." && pwd)"
"$root_dir/scripts/ensure-env.sh"
"$root_dir/scripts/preflight.sh"
