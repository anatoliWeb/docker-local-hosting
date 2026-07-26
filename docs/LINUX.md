# Налаштування на Linux

## Вимоги

- Docker Engine 24+
- Docker Compose plugin v2+
- mkcert
- bash

## Встановлення Docker Engine
```bash
# Для Ubuntu/Debian:
sudo apt update
sudo apt install docker.io docker-compose-v2
sudo systemctl enable --now docker
```

Для інших дистрибутивів див. [docs.docker.com](https://docs.docker.com/engine/install/).

## Встановлення mkcert
```bash
# Ubuntu/Debian:
sudo apt install libnss3-tools
curl -JLO "https://dl.filippo.io/mkcert/latest?for=linux/amd64"
chmod +x mkcert-*-linux-amd64
sudo mv mkcert-*-linux-amd64 /usr/local/bin/mkcert
```

або через пакетний менеджер (якщо доступно):
```bash
# Arch:
sudo pacman -S mkcert
```

## Створення локального CA
```bash
mkcert -install
```

## Генерація сертифіката
```bash
./scripts/generate-certs.sh
```

## /etc/hosts
Відредагуйте `/etc/hosts` з правами root:
```bash
sudo nano /etc/hosts
```

Додайте записи:
```
192.168.1.100 demo.home.arpa
192.168.1.100 traefik.home.arpa
```

## Firewall
```bash
# Якщо використовуєте ufw:
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
```

## Запуск
```bash
chmod +x scripts/*.sh
./scripts/setup.sh
docker compose up -d
```

## Перевірка через curl
```bash
curl -I https://demo.home.arpa
curl -I https://traefik.home.arpa
```
