# Docker Local Hosting

Локальний Docker-хостинг із Traefik, HTTPS, автоматичною публікацією контейнерів і підтримкою Windows та Linux.

## Призначення

Запустіть центральний Traefik-проксі один раз, і всі ваші локальні Docker-проєкти будуть доступні через красиві домени з HTTPS:

- `https://demo.home.arpa`
- `https://traefik.home.arpa`
- `https://crm.home.arpa`
- `https://api.crm.home.arpa`

Жодних ручних списків проєктів, жодних файлів конфігурації на кожен новий сайт. Просто підключіть контейнер до мережі `local-hosting` і додайте кілька labels.

## Архітектура

```
                  HTTP/HTTPS :80 :443
                         |
                    Traefik (v3)
                    /          \
          Docker Socket Proxy  File Provider
               |                    |
          Docker socket        TLS config
               |
     Контейнери в мережі
        local-hosting
```

### Компоненти

| Компонент | Версія | Призначення |
|-----------|--------|-------------|
| Traefik | v3.7.9 | Reverse proxy, автоматичне виявлення контейнерів |
| Docker Socket Proxy | v0.4.2 | Безпечний прошарок між Traefik і Docker socket |
| Nginx (demo) | stable-alpine | Демонстраційний сайт |
| mkcert | latest | Локальний CA для HTTPS |

### Схема роботи

1. Користувач запускає окремий Docker-проєкт.
2. Контейнер підключено до зовнішньої мережі `local-hosting`.
3. Контейнер має Traefik labels (наприклад, `traefik.enable=true`).
4. Docker Socket Proxy дозволяє Traefik читати список контейнерів.
5. Traefik автоматично створює маршрут.
6. Сайт доступний через локальний HTTPS-домен.
7. Після зупинки контейнера маршрут автоматично зникає.

## Системні вимоги

- **Windows**: Windows 10/11, Docker Desktop, PowerShell 5.1+
- **Linux**: Docker Engine 24+, Docker Compose v2+, bash
- **Мережа**: Локальна LAN із DHCP reservation для центрального ПК
- **mkcert**: Для генерації локальних TLS-сертифікатів

## Швидкий старт (Windows)

```powershell
# 1. Встановіть mkcert
winget install mkcert
mkcert -install

# 2. Згенеруйте сертифікати
.\scripts\generate-certs.ps1

# 3. Створіть мережу
.\scripts\create-network.ps1

# 4. Налаштуйте .env
Copy-Item .env.example .env
# Відредагуйте .env, додайте Basic Auth hash

# 5. Запустіть перевірку
.\scripts\setup.ps1

# 6. Запустіть проєкт
docker compose up -d
```

## Швидкий старт (Linux)

```bash
# 1. Встановіть mkcert
sudo apt install libnss3-tools
curl -JLO "https://dl.filippo.io/mkcert/latest?for=linux/amd64"
chmod +x mkcert-*-linux-amd64
sudo mv mkcert-*-linux-amd64 /usr/local/bin/mkcert
mkcert -install

# 2. Згенеруйте сертифікати
chmod +x scripts/*.sh
./scripts/generate-certs.sh

# 3. Створіть мережу
./scripts/create-network.sh

# 4. Налаштуйте .env
cp .env.example .env

# 5. Запустіть перевірку
./scripts/setup.sh

# 6. Запустіть проєкт
docker compose up -d
```

## Налаштування .env

Скопіюйте `.env.example` у `.env` та відредагуйте:

```dotenv
LOCAL_DOMAIN=home.arpa
TRAEFIK_DASHBOARD_HOST=traefik.home.arpa
DEMO_HOST=demo.home.arpa
TRAEFIK_BASIC_AUTH=
TZ=Europe/Kyiv
COMPOSE_PROJECT_NAME=docker-local-hosting
```

## Створення Basic Auth

Для захисту Dashboard створіть hash пароля:

```bash
# Linux / macOS
echo $(htpasswd -nb admin ваш_пароль) | sed -e 's/\$/\$\$/g'

# Windows (через Git Bash або WSL)
echo $(htpasswd -nb admin ваш_пароль) | sed -e 's/\$/\$\$/g'
```

Отриманий рядок додайте в `.env`:
```dotenv
TRAEFIK_BASIC_AUTH=admin:$$2y$$10$$...
```

Зверніть увагу: кожен символ `$` екранований як `$$` для Docker Compose.

## Генерація сертифікатів

```powershell
.\scripts\generate-certs.ps1
```

Або вручну:
```powershell
mkcert -cert-file certs/home.arpa.pem -key-file certs/home.arpa-key.pem home.arpa *.home.arpa
```

Докладніше: [docs/HTTPS.md](docs/HTTPS.md).

## Створення Docker-мережі

```powershell
.\scripts\create-network.ps1
```

Або вручну:
```powershell
docker network create local-hosting --driver bridge --attachable
```

## Запуск

```powershell
docker compose up -d
```

## Записи hosts

Додайте в файл hosts (від адміністратора):

```
192.168.1.100 demo.home.arpa
192.168.1.100 traefik.home.arpa
```

**Windows**: `C:\Windows\System32\drivers\etc\hosts`
**Linux**: `/etc/hosts`

Файл hosts не підтримує wildcard. Кожен новий домен — окремий рядок.

## Відкриття demo

`https://demo.home.arpa`

## Відкриття Dashboard

`https://traefik.home.arpa`

Введіть логін і пароль, які ви налаштували в `TRAEFIK_BASIC_AUTH`.

## Підключення нового проєкту

Додайте до вашого `compose.yaml`:

```yaml
services:
  app:
    image: nginx:stable-alpine
    networks:
      - local-hosting
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.myapp.rule=Host(`myapp.home.arpa`)"
      - "traefik.http.routers.myapp.entrypoints=websecure"
      - "traefik.http.routers.myapp.tls=true"
      - "traefik.http.services.myapp.loadbalancer.server.port=80"

networks:
  local-hosting:
    external: true
```

Докладніше: [docs/ADDING-A-PROJECT.md](docs/ADDING-A-PROJECT.md).

## Laravel-приклад

```yaml
services:
  nginx:
    image: nginx:stable-alpine
    networks:
      - local-hosting
      - laravel
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.myproject.rule=Host(`myproject.home.arpa`)"
      - "traefik.http.routers.myproject.entrypoints=websecure"
      - "traefik.http.routers.myproject.tls=true"
      - "traefik.http.services.myproject.loadbalancer.server.port=80"

  php-fpm:
    image: php:8.3-fpm-alpine
    networks:
      - laravel

networks:
  local-hosting:
    external: true
  laravel:
    internal: true
```

Докладніше: [examples/laravel.compose.example.yaml](examples/laravel.compose.example.yaml).

## Доступ із LAN

Докладніше: [docs/LAN.md](docs/LAN.md).

Коротко:
1. Додайте записи hosts на клієнтському ПК.
2. Встановіть CA-сертифікат на клієнтському ПК.
3. Налаштуйте Windows Firewall.

## Зупинка

```powershell
docker compose down
```

## Перезапуск

```powershell
docker compose restart
```

## Перегляд логів

```powershell
docker compose logs -f
docker compose logs -f traefik
docker compose logs -f demo
```

## Оновлення образів

```powershell
docker compose pull
docker compose up -d
```

## Діагностика

```powershell
docker compose ps
docker compose logs --tail=100
curl -I https://demo.home.arpa
curl -I https://traefik.home.arpa
```

## Безпека

- Traefik не має прямого доступу до Docker socket — використовується Docker Socket Proxy.
- Docker Socket Proxy має read-only доступ.
- Dashboard захищений Basic Auth.
- `exposedByDefault: false` — лише явно позначені контейнери публікуються.
- `.env` та сертифікати виключені з Git.

Докладніше: [SECURITY.md](SECURITY.md).

## Відомі обмеження

- Файл hosts не підтримує wildcard — кожен домен окремо.
- Вкладені піддомени (`api.crm.home.arpa`) не покриваються wildcard `*.home.arpa`.
- Рекомендується використовувати однорівневі домени (`crm-api.home.arpa`).
- DNS-сервер не входить у MVP — див. [docs/LOCAL-DNS.md](docs/LOCAL-DNS.md).
- Не призначено для production-середовища.

## Roadmap

- [x] Traefik v3 з Docker provider
- [x] Docker Socket Proxy
- [x] HTTPS через mkcert
- [x] Basic Auth для Dashboard
- [x] Автоматичне виявлення контейнерів
- [x] Демонстраційний сайт
- [x] Приклади підключення
- [ ] Власна адмін-панель для перегляду сервісів
- [ ] Підтримка вкладених піддоменів через SAN
- [ ] Інтеграція з локальним DNS (AdGuard Home, Pi-hole)
- [ ] Автоматичне оновлення сертифікатів

## Ліцензія

MIT License. Див. [LICENSE](LICENSE).

## Використаний upstream

Архітектурні референси:
- [BretFisher/compose-dev-tls](https://github.com/BretFisher/compose-dev-tls) (Unlicense)
- [tecnativa/docker-socket-proxy](https://github.com/Tecnativa/docker-socket-proxy) (Apache 2.0)
- [traefik/traefik](https://github.com/traefik/traefik) (MIT)

Докладніше: [docs/UPSTREAM-REPOSITORY.md](docs/UPSTREAM-REPOSITORY.md).
