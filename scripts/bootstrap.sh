#!/bin/sh
# Bootstrap script — перевіряє готовність перед запуском Traefik.
# Запускається як окремий сервіс compose.yaml.

set -Eeuo pipefail

echo "================================================"
echo "  Docker Local Hosting — bootstrap перевірка"
echo "================================================"

# TLS сертифікат
echo ""
echo "==> 1. TLS сертифікат"
if [ -f "${TLS_CERT_FILE}" ]; then
    size=$(stat -c%s "${TLS_CERT_FILE}" 2>/dev/null || stat -f%z "${TLS_CERT_FILE}" 2>/dev/null || echo 0)
    if [ "$size" -gt 0 ]; then
        echo "[OK] Сертифікат знайдено"
    else
        echo "[ПОМИЛКА] Сертифікат порожній: ${TLS_CERT_FILE}"
        exit 1
    fi
else
    echo "[ПОМИЛКА] Сертифікат не знайдено: ${TLS_CERT_FILE}"
    echo ""
    echo "Згенеруйте сертифікати на хості:"
    echo "  .\\scripts\\generate-certs.ps1"
    echo "  або: mkcert -cert-file certs/home.arpa.pem -key-file certs/home.arpa-key.pem home.arpa *.home.arpa"
    exit 1
fi

# TLS ключ
echo ""
echo "==> 2. TLS ключ"
if [ -f "${TLS_KEY_FILE}" ]; then
    size=$(stat -c%s "${TLS_KEY_FILE}" 2>/dev/null || stat -f%z "${TLS_KEY_FILE}" 2>/dev/null || echo 0)
    if [ "$size" -gt 0 ]; then
        echo "[OK] Ключ знайдено"
    else
        echo "[ПОМИЛКА] Ключ порожній: ${TLS_KEY_FILE}"
        exit 1
    fi
else
    echo "[ПОМИЛКА] Ключ не знайдено: ${TLS_KEY_FILE}"
    exit 1
fi

# Підсумок
echo ""
echo "==> Підсумок"
echo "[OK] Bootstrap завершено успішно"
exit 0
