# Налаштування на Linux

## Одноразова підготовка

```bash
# Docker
sudo apt update
sudo apt install docker.io docker-compose-v2
sudo systemctl enable --now docker

# mkcert
sudo apt install libnss3-tools
curl -JLO "https://dl.filippo.io/mkcert/latest?for=linux/amd64"
chmod +x mkcert-*-linux-amd64
sudo mv mkcert-*-linux-amd64 /usr/local/bin/mkcert
mkcert -install
```

## Щоденний запуск

```bash
docker compose up -d
```

Або:
```bash
chmod +x scripts/*.sh
./scripts/start.sh
```

## Скрипти

```bash
./scripts/start.sh          # запуск
./scripts/stop.sh           # зупинка
./scripts/status.sh         # статус
./scripts/logs.sh traefik   # логи
./scripts/update.sh         # оновлення
./scripts/setup.sh          # налаштування
./scripts/generate-certs.sh # сертифікати
```

## /etc/hosts

```bash
./scripts/show-hosts-entry.sh
sudo nano /etc/hosts
```

## Firewall

```bash
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
```
