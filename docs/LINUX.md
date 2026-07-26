# Налаштування на Linux

## Вимоги

- Docker Engine 24+
- Docker Compose plugin v2+
- mkcert
- bash

## Встановлення Docker Engine

```bash
# Ubuntu/Debian:
sudo apt update
sudo apt install docker.io docker-compose-v2
sudo systemctl enable --now docker
```

## Встановлення mkcert

```bash
sudo apt install libnss3-tools
curl -JLO "https://dl.filippo.io/mkcert/latest?for=linux/amd64"
chmod +x mkcert-*-linux-amd64
sudo mv mkcert-*-linux-amd64 /usr/local/bin/mkcert
mkcert -install
```

## Повне налаштування

```bash
# 1. Налаштуйте .env
cp .env.example .env

# 2. Запустіть скрипт налаштування
chmod +x scripts/*.sh
./scripts/setup.sh

# 3. Запустіть проєкт
docker compose up -d
```

Скрипт `setup.sh` автоматично:
- Перевіряє Docker, .env, мережу, сертифікати
- Створює мережу (якщо `AUTO_CREATE_NETWORK=true`)
- Генерує сертифікати (якщо `AUTO_GENERATE_CERTS=true`)

## /etc/hosts

```bash
sudo nano /etc/hosts
```

Додайте записи:

```
127.0.0.1 demo.home.arpa
127.0.0.1 traefik.home.arpa
```

Для підказки:

```bash
./scripts/show-hosts-entry.sh
```

## Firewall

```bash
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
```

## Перевірка

```bash
curl -I https://demo.home.arpa
curl -I https://traefik.home.arpa
```
