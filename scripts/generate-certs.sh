#!/bin/sh
# Генерує локальний TLS-сертифікат для home.arpa через mkcert.
# Перевіряє наявність mkcert, локального CA та створює сертифікат.

set -Eeuo pipefail

certs_dir="$(cd "$(dirname "$0")/.." && pwd)/certs"
mkdir -p "$certs_dir"

# Перевірка mkcert
if ! command -v mkcert >/dev/null 2>&1; then
    echo "ПОМИЛКА: mkcert не знайдено."
    echo ""
    echo "Встановіть mkcert:"
    echo "  macOS: brew install mkcert nss"
    echo "  Linux: див. https://github.com/FiloSottile/mkcert"
    echo ""
    echo "Після встановлення запустіть: mkcert -install"
    exit 1
fi
echo "mkcert знайдено: $(command -v mkcert)"

# Встановлення локального CA
if ! mkcert -install 2>&1; then
    echo "ПОМИЛКА: Не вдалося встановити локальний CA."
    echo "Спробуйте вручну: mkcert -install"
    exit 1
fi

# Шлях до CA
ca_path=$(mkcert -CAROOT 2>&1)
echo "Локальний CA знаходиться за шляхом: $ca_path"

# Генерація сертифіката
echo "Генерую сертифікат для доменів: home.arpa, *.home.arpa"
echo "Увага: wildcard *.home.arpa не покриває вкладені піддомени."

mkcert -cert-file "$certs_dir/home.arpa.pem" \
       -key-file "$certs_dir/home.arpa-key.pem" \
       "home.arpa" "*.home.arpa"

echo ""
echo "Сертифікати згенеровано успішно:"
echo "  Сертифікат: $certs_dir/home.arpa.pem"
echo "  Приватний ключ: $certs_dir/home.arpa-key.pem"
echo ""
echo "ВАЖЛИВО: Приватний ключ не комітьте в Git."
echo "ВАЖЛИВО: Не копіюйте CA private key на інші комп'ютери."
echo ""
echo "Наступні кроки:"
echo "  1. Додайте записи у /etc/hosts"
echo "  2. Запустіть: docker compose up -d"
