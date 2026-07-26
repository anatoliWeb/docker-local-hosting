# Налаштування на Windows

## Одноразова підготовка

```powershell
winget install FiloSottile.mkcert
mkcert -install
```

Або:
```powershell
.\scripts\install-prerequisites.ps1
```

## Запуск

```powershell
.\start.ps1
```

З `cmd.exe` використовуйте `start.cmd`.

Під час першого запуску `start.ps1` копіює `.env.example` у `.env`.
Наявний `.env` не змінюється. Docker Compose не може створити `.env` сам,
бо читає змінні до запуску контейнерів.

Після підготовки допустимий прямий запуск:

```powershell
docker compose up -d
```

## Що робить start.ps1

1. Створює `.env` лише за відсутності.
2. Перевіряє Docker, daemon, Compose та preflight.
3. Перевіряє Basic Auth і TLS, пропонує безпечну генерацію.
4. Валідує `docker compose config`.
5. Запускає `docker compose up -d` і очікує healthcheck.
6. Показує URL і посилання на ручний чекліст.

## Скрипти

| Команда | Опис |
|---------|------|
| `.\start.ps1` | Головний запуск Windows |
| `start.cmd` | Обгортка для cmd.exe |
| `.\scripts\start.ps1` | Сумісна обгортка |
| `.\scripts\stop.ps1` | Зупинка |
| `.\scripts\status.ps1` | Статус |
| `.\scripts\logs.ps1 traefik` | Логи Traefik |
| `.\scripts\update.ps1` | Оновлення образів |
| `.\scripts\setup.ps1` | Налаштування |
| `.\scripts\generate-certs.ps1` | Сертифікати |
| `.\scripts\show-hosts-entry.ps1` | Hosts підказка |

## Мережа

Створюється автоматично при `docker compose up -d`.
`docker compose down` не видаляє мережу, якщо вона використовується.

## Файл hosts

```powershell
.\scripts\show-hosts-entry.ps1
```

Додайте у `C:\Windows\System32\drivers\etc\hosts` (адміністратор):
```
127.0.0.1 traefik.home.arpa
127.0.0.1 demo.home.arpa
```

## Firewall

Порти 80 та 443 мають бути відкриті для доступу з LAN.

## PowerShell Execution Policy

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```
