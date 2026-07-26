# Docker Local Hosting

Локальний Docker-хостинг із Traefik, HTTPS, автоматичним виявленням сервісів.

## Призначення

Запустіть центральний Traefik-проксі один раз — і всі ваші локальні Docker-проєкти
доступні через HTTPS-домени без перезапуску Traefik:

- `https://demo.home.arpa`
- `https://traefik.home.arpa`
- `https://myapp.home.arpa`
- `wss://socket.home.arpa`

## Архітектура

```
                  HTTP/HTTPS :80 :443
                         |
                    Traefik (v3)
                    /          \
          Docker Socket Proxy  File Provider
               |                    |
          Docker socket        TLS config
               |              External services
     Docker контейнери        Dynamic reload
     (watch: true)            (watch: true)
```

### Компоненти

| Компонент | Версія | Призначення |
|-----------|--------|-------------|
| Traefik | v3.7.9 | Reverse proxy, auto-discovery |
| Docker Socket Proxy | v0.4.2 | Безпечний прошарок до Docker socket |
| Nginx (demo) | 1.27-alpine | Демонстраційний сайт |
| Bootstrap | 3.20 | One-shot валідація TLS перед запуском |
| mkcert | latest | Локальний CA (host, не container) |

### Як це працює

1. `docker compose up -d` створює мережу, запускає bootstrap, Traefik, proxy, demo.
2. Traefik автоматично відстежує Docker events (watch: true).
3. Новий контейнер з `traefik.enable=true` у мережі `local-hosting` отримує маршрут без restart.
4. Скрипти зовнішніх сервісів копіюють registry у контейнер, щоб File Provider
   оновив маршрути на Windows Docker Desktop без recreate Traefik.
5. При зупинці контейнера маршрут автоматично зникає.

## Одноразова підготовка (Windows)

```powershell
# 1. Встановіть mkcert
winget install FiloSottile.mkcert
mkcert -install

# 2. Створіть облікові дані для Dashboard
.\scripts\generate-dashboard-auth.ps1

# 3. Згенеруйте сертифікати
.\scripts\generate-certs.ps1

# 4. Додайте домени у hosts
.\scripts\show-hosts-entry.ps1
```

Або автоматично:
```powershell
.\scripts\generate-dashboard-auth.ps1
.\scripts\generate-certs.ps1
.\start.ps1
```

## Щоденний запуск

```powershell
.\start.ps1
```

`start.ps1` створює `.env` з `.env.example` лише при першому запуску.
Наявний `.env` не перезаписується. Після підготовки `docker compose up -d`
працює напряму, але не створює `.env`: це робить host entrypoint до запуску Compose.

### Linux

```bash
# Одноразова підготовка
sudo apt install libnss3-tools
curl -JLO "https://dl.filippo.io/mkcert/latest?for=linux/amd64"
chmod +x mkcert-*-linux-amd64
sudo mv mkcert-*-linux-amd64 /usr/local/bin/mkcert
mkcert -install

cp .env.example .env
chmod +x scripts/*.sh
./scripts/generate-certs.sh
./scripts/setup.sh

# Щоденний запуск
docker compose up -d
# або
./scripts/start.sh
```

## Bootstrap TLS

Перед запуском Traefik, compose запускає `bootstrap` сервіс, який:
- перевіряє наявність TLS сертифіката;
- перевіряє, що файли не порожні;
- показує українську помилку при відсутності;
- завершується з кодом 0 лише при готовності.

Traefik залежить від bootstrap:
```yaml
depends_on:
  bootstrap:
    condition: service_completed_successfully
```

## Автоматичне створення мережі

Мережа `local-hosting` створюється автоматично при `docker compose up -d`
(без `external: true` у центральному compose).

Сторонні проєкти використовують:
```yaml
networks:
  local-hosting:
    external: true
    name: ${LOCAL_HOSTING_NETWORK:-local-hosting}
```

`docker compose down` не видаляє мережу, якщо до неї підключені інші контейнери.

## Додавання нового проєкту

### Спосіб 1: Generator (override, безпечно)

```powershell
.\scripts\add-project.ps1 `
  -ProjectPath "E:\Projects\myapp" `
  -Domain "myapp.home.arpa" `
  -Service "web" `
  -InternalPort 8080
```

Створює `compose.traefik.override.yaml` поруч із `compose.yaml`.
Оригінальний compose не змінюється.

```powershell
docker compose -f compose.yaml -f compose.traefik.override.yaml --env-file .env.traefik up -d
```

### Спосіб 2: Шаблон

```bash
cp -r examples/project-template projects/myapp
docker compose -f projects/myapp/compose.yaml up -d
```

### Спосіб 3: Вручну

Додайте до compose.yaml:
```yaml
services:
  app:
    image: nginx:1.27-alpine
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

## Порт

### Режим A: автоматичний

Якщо image має рівно один EXPOSE, Traefik може використати його.
Не задавайте `server.port` в цьому випадку.

### Режим B: явний (рекомендований)

Завжди задавайте порт явно:
```yaml
traefik.http.services.myapp.loadbalancer.server.port: "${APP_INTERNAL_PORT:-8080}"
```

Check-project покаже:
- `АВТОВИЗНАЧЕННЯ БЕЗПЕЧНЕ` — один expose;
- `ПОТРIБНО ВКАЗАТИ APP_INTERNAL_PORT` — кілька або жодного.

## Домен

Домен має задаватися явно в `.env`:
```dotenv
APP_DOMAIN=myapp.home.arpa
```

Helper-скрипт може показати домен, але не публікує контейнер без згоди.

## Зовнішні сервіси за IP і портом

```powershell
.\scripts\add-external-service.ps1 `
  -Name camera `
  -Domain camera.home.arpa `
  -Url http://192.168.1.50:9000
```

Оновлює `config/traefik/dynamic/external-services.yaml` — єдиний registry-файл.
На Windows Docker Desktop скрипт копіює registry у mounted dynamic directory,
щоб File Provider отримав файлову подію без recreate контейнера.

Для Windows host використовуйте `http://host.docker.internal:9000`.
Не використовуйте `127.0.0.1` або `localhost` — всередині Traefik це контейнер.

Керування:
- `add-external-service.ps1/.sh` — додати або оновити
- `remove-external-service.ps1/.sh` — видалити
- `list-external-services.ps1/.sh` — список

## WebSocket

Протокол WebSocket не потребує додаткових middleware в Traefik.
HTTP Upgrade передається автоматично.

```yaml
traefik.http.routers.ws-demo.rule=Host(`socket.home.arpa`)
```

Приклад: [examples/websocket/](examples/websocket/)

## Скрипти

| Скрипт | Призначення |
|--------|-------------|
| `install-prerequisites.ps1/.sh` | Одноразова підготовка (mkcert, CA, Docker) |
| `generate-dashboard-auth.ps1/.sh` | Створення secrets/traefik-users для Basic Auth |
| `generate-certs.ps1/.sh` | Генерація TLS через mkcert |
| `setup.ps1/.sh` | Перевірка та налаштування |
| `preflight.ps1/.sh` | Повна перевірка готовності без змін |
| `start.ps1`, `start.cmd` | Головний запуск Windows |
| `scripts/ensure-env.ps1/.sh` | Створити `.env`, не перезаписуючи наявний |
| `scripts/start.ps1/.sh` | Сумісний запуск |
| `stop.ps1/.sh` | Зупинка без видалення мережі |
| `destroy.ps1/.sh` | Повне видалення (мережа, образи) з підтвердженням |
| `status.ps1/.sh` | Статус сервісів |
| `logs.ps1/.sh` | Перегляд логів |
| `update.ps1/.sh` | Оновлення образів |
| `add-project.ps1/.sh` | Інтеграція проєкту через override |
| `add-external-service.ps1/.sh` | Додати/оновити зовнішній сервіс |
| `remove-external-service.ps1/.sh` | Видалити зовнішній сервіс |
| `list-external-services.ps1/.sh` | Список зовнішніх сервісів |
| `check-project.ps1/.sh` | Валідація compose.yaml |
| `show-hosts-entry.ps1/.sh` | Підказка для hosts |

## TCP/UDP

HTTP/HTTPS/WebSocket маршрути додаються без restart.
TCP/UDP вимагають:
- додати entrypoint у static config;
- опублікувати host port у Compose;
- recreate/restart Traefik.

Профілі: [profiles/tcp/](profiles/tcp/), [profiles/udp/](profiles/udp/)

## Команди

```powershell
.\start.ps1                  # запуск
.\scripts\stop.ps1           # зупинка (мережа зберігається)
.\scripts\destroy.ps1        # повне видалення (мережа, образи)
.\scripts\status.ps1         # статус
.\scripts\logs.ps1 traefik   # логи Traefik
.\scripts\update.ps1         # оновлення
.\scripts\preflight.ps1      # перевірка готовності
```

## Діагностика

```powershell
curl.exe -sk -H "Host: demo.home.arpa" https://localhost/
curl.exe -sk -H "Host: traefik.home.arpa" https://localhost/
docker compose logs --tail=50
```

## Відомі обмеження

- Файл hosts не підтримує wildcard — кожен домен окремо.
- Вкладені піддомени не покриваються wildcard `*.home.arpa`.
- TCP/UDP потребують restart Traefik для нового entrypoint.
- mkcert не встановлює CA в контейнер — CA на хості.
- Не призначено для production.

## Документація

- [ADDING-A-PROJECT.md](docs/ADDING-A-PROJECT.md)
- [HTTPS.md](docs/HTTPS.md)
- [WINDOWS.md](docs/WINDOWS.md)
- [LINUX.md](docs/LINUX.md)
- [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)
- [SIP.md](docs/SIP.md)
- [FILE-TRANSFER.md](docs/FILE-TRANSFER.md)
- [LAN.md](docs/LAN.md)
- [LOCAL-DNS.md](docs/LOCAL-DNS.md)

## Roadmap

- [x] Traefik v3 з Docker provider + File provider
- [x] Docker Socket Proxy (безпечний)
- [x] HTTPS через mkcert
- [x] Basic Auth для Dashboard
- [x] Автоматичне виявлення контейнерів (watch: true)
- [x] Bootstrap TLS перевірка
- [x] Auto-network через compose
- [x] Dynamic File Provider hot-reload
- [x] External IP:port сервіси
- [x] WebSocket/WSS
- [x] Override generator (безпечна інтеграція)
- [x] Lifecycle скрипти
- [x] TCP/UDP профілі
- [ ] Власна адмін-панель
- [ ] Локальний DNS (AdGuard, Pi-hole)
- [ ] Повна SIP/RTP підтримка
