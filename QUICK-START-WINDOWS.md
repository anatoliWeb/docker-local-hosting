# Швидкий старт на Windows

Повний сценарій запуску `docker-local-hosting` на Windows 10/11 з Docker Desktop.

## Передумови

- Windows 10 або 11
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (встановлений і запущений)
- [Git](https://git-scm.com/) (рекомендовано)
- PowerShell 5.1+

## 1. Відкрийте PowerShell

```powershell
Set-Location E:\_programming_\_project_\docker-local-hosting
```

## 2. .env

```powershell
Copy-Item .env.example .env
```

## 3. Встановіть залежності

```powershell
.\scripts\install-prerequisites.ps1
```

Підтвердьте встановлення mkcert, CA та зміну execution policy.

## 4. Створіть облікові дані Dashboard

```powershell
.\scripts\generate-dashboard-auth.ps1
```

Введіть логін і пароль. Пароль не відображається.

## 5. Згенеруйте сертифікати

```powershell
.\scripts\generate-certs.ps1
```

## 6. Додайте домени в hosts

Відредагуйте `C:\Windows\System32\drivers\etc\hosts` від імені адміністратора.
Додайте:

```text
127.0.0.1 demo.home.arpa
127.0.0.1 traefik.home.arpa
127.0.0.1 myapp.home.arpa
127.0.0.1 socket.home.arpa
```

## 7. Запустіть

```powershell
.\scripts\start.ps1
```

Або напряму:

```powershell
docker compose up -d
```

## 8. Перевірте

- `https://demo.home.arpa` — демо-сторінка
- `https://traefik.home.arpa/dashboard/` — Dashboard (введіть логін/пароль)

## 9. Зупинка

```powershell
.\scripts\stop.ps1
```

## 10. Повне видалення

```powershell
.\scripts\destroy.ps1
```

## Детальніше

- [docs/MANUAL-TESTING-WINDOWS.md](docs/MANUAL-TESTING-WINDOWS.md) — повний чекліст
- [README.md](README.md) — загальна документація
- [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) — вирішення проблем
