# Docker Local Hosting

Локальний Docker-хостинг із Traefik, HTTPS, автоматичною публікацією контейнерів і підтримкою Windows та Linux.

## Призначення

Запустіть центральний Traefik-проксі один раз, і всі ваші локальні Docker-проєкти будуть доступні через красиві домени з HTTPS:

- `https://demo.home.arpa`
- `https://traefik.home.arpa`
- `https://myapp.home.arpa`

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

1. Traefik отримує HTTP/HTTPS трафік на порти 80/443.
2. Traefik читає Docker API через Docker Socket Proxy.
3. Traefik знаходить контейнери з `traefik.enable=true` у мережі `local-hosting`.
4. Traefik автоматично створює маршрути на основі labels контейнерів.
5. При зупинці контейнера маршрут автоматично зникає.

## Системні вимоги

- **Windows**: Windows 10/11, Docker Desktop, PowerShell 5.1+
- **Linux**: Docker Engine 24+, Docker Compose v2+, bash
- **mkcert**: Для генерації локальних TLS-сертифікатів

## Швидкий старт (Windows)

```powershell
# 1. Встановіть mkcert
winget install mkcert
mkcert -install

# 2. Налаштуйте .env
Copy-Item .env.example .env
# Відредагуйте .env, особливо TRAEFIK_BASIC_AUTH

# 3. Запустіть налаштування (згенерує сертифікати, створить мережу)
.\scripts\setup.ps1

# 4. Запустіть проєкт
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

# 2. Налаштуйте .env
cp .env.example .env

# 3. Запустіть налаштування
chmod +x scripts/*.sh
./scripts/setup.sh

# 4. Запустіть проєкт
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
LOCAL_HOSTING_NETWORK=local-hosting
TLS_CERT_FILE=./certs/home.arpa.pem
TLS_KEY_FILE=./certs/home.arpa-key.pem
MKCERT_DOMAINS=home.arpa *.home.arpa
AUTO_GENERATE_CERTS=true
AUTO_CREATE_NETWORK=true
```

### Нові змінні Stage 2

| Змінна | Призначення |
|--------|-------------|
| `LOCAL_HOSTING_NETWORK` | Назва зовнішньої Docker-мережі |
| `TLS_CERT_FILE` | Шлях до файлу сертифіката |
| `TLS_KEY_FILE` | Шлях до файлу ключа |
| `MKCERT_DOMAINS` | Домени для генерації сертифіката |
| `AUTO_GENERATE_CERTS` | Авто-генерація сертифікатів (true/false) |
| `AUTO_CREATE_NETWORK` | Авто-створення мережі (true/false) |

## Скрипти

| Скрипт | Призначення |
|--------|-------------|
| `scripts/setup.ps1` / `.sh` | Повна перевірка та налаштування |
| `scripts/generate-certs.ps1` / `.sh` | Генерація TLS-сертифікатів |
| `scripts/create-network.ps1` / `.sh` | Створення Docker-мережі |
| `scripts/check-project.ps1` / `.sh` | Перевірка сумісності проєкту |
| `scripts/show-hosts-entry.ps1` / `.sh` | Підказка для hosts-файлу |

## Додавання нового проєкту

Використовуйте шаблон:

```bash
cp -r examples/project-template projects/myapp
```

Або додайте до свого `compose.yaml`:

```yaml
services:
  app:
    image: nginx:stable-alpine
    networks:
      - ${LOCAL_HOSTING_NETWORK:-local-hosting}
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.myapp.rule=Host(`myapp.home.arpa`)"
      - "traefik.http.routers.myapp.entrypoints=websecure"
      - "traefik.http.routers.myapp.tls=true"
      - "traefik.http.services.myapp.loadbalancer.server.port=80"

networks:
  local-hosting:
    external: true
    name: ${LOCAL_HOSTING_NETWORK:-local-hosting}
```

Докладніше: [docs/ADDING-A-PROJECT.md](docs/ADDING-A-PROJECT.md), [examples/project-template/](examples/project-template/).

## Перевірка проєкту

```powershell
.\scripts\check-project.ps1 .\projects\myapp
```

## Записи hosts

```powershell
.\scripts\show-hosts-entry.ps1
```

Додайте в файл hosts (від адміністратора):

```
127.0.0.1 traefik.home.arpa
127.0.0.1 demo.home.arpa
127.0.0.1 myapp.home.arpa
```

**Windows**: `C:\Windows\System32\drivers\etc\hosts`
**Linux**: `/etc/hosts`

## Документація

- [ADDING-A-PROJECT.md](docs/ADDING-A-PROJECT.md) — додавання нового проєкту
- [HTTPS.md](docs/HTTPS.md) — сертифікати та HTTPS
- [WINDOWS.md](docs/WINDOWS.md) — налаштування Windows
- [LINUX.md](docs/LINUX.md) — налаштування Linux
- [LAN.md](docs/LAN.md) — доступ із локальної мережі
- [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) — діагностика

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

## Відомі обмеження

- Файл hosts не підтримує wildcard — кожен домен окремо.
- Вкладені піддомени (`api.crm.home.arpa`) не покриваються wildcard `*.home.arpa`.
- Рекомендується використовувати однорівневі домени.
- DNS-сервер не входить у Stage 1 — див. [docs/LOCAL-DNS.md](docs/LOCAL-DNS.md).
- Не призначено для production-середовища.

## Roadmap

- [x] Traefik v3 з Docker provider
- [x] Docker Socket Proxy
- [x] HTTPS через mkcert
- [x] Basic Auth для Dashboard
- [x] Автоматичне виявлення контейнерів
- [x] Демонстраційний сайт
- [x] Приклади підключення
- [x] Stage 2: покращення сертифікатів, .env, шаблони
- [ ] Власна адмін-панель для перегляду сервісів
- [ ] Підтримка вкладених піддоменів через SAN
- [ ] Інтеграція з локальним DNS (AdGuard Home, Pi-hole)
- [ ] Автоматичне оновлення сертифікатів

## Ліцензія

MIT License.

## Використаний upstream

- [BretFisher/compose-dev-tls](https://github.com/BretFisher/compose-dev-tls) (Unlicense)
- [tecnativa/docker-socket-proxy](https://github.com/Tecnativa/docker-socket-proxy) (Apache 2.0)
- [traefik/traefik](https://github.com/traefik/traefik) (MIT)

Докладніше: [docs/UPSTREAM-REPOSITORY.md](docs/UPSTREAM-REPOSITORY.md).
