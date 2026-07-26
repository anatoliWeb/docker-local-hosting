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

## Щоденний запуск

```powershell
docker compose up -d
```

Або рекомендований варіант:
```powershell
.\scripts\start.ps1
```

## Що робить start.ps1

1. Перевіряє Docker, .env.
2. Перевіряє сертифікати, пропонує згенерувати.
3. Валідує compose config.
4. Запускає `docker compose up -d`.
5. Очікує healthcheck.
6. Показує URL.

## Скрипти

| Команда | Опис |
|---------|------|
| `.\scripts\start.ps1` | Запуск |
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
