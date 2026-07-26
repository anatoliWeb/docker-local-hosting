# Налаштування на Windows

## Вимоги

- Windows 10 або 11
- Docker Desktop (остання версія)
- PowerShell 5.1 або новіший
- mkcert

## Встановлення Docker Desktop

1. Завантажте Docker Desktop з [docker.com](https://www.docker.com/products/docker-desktop/).
2. Встановіть, дотримуючись інструкцій.
3. Після встановлення переконайтеся, що Docker Engine працює (іконка в треї).

## Встановлення mkcert

```powershell
winget install mkcert
```

Або вручну: завантажте `mkcert-v*-windows-amd64.exe` з https://github.com/FiloSottile/mkcert/releases та додайте в PATH.

## Повне налаштування

```powershell
# 1. Встановіть CA
mkcert -install

# 2. Налаштуйте .env
Copy-Item .env.example .env

# 3. Запустіть скрипт налаштування
.\scripts\setup.ps1

# 4. Запустіть проєкт
docker compose up -d
```

Скрипт `setup.ps1` автоматично:
- Перевіряє Docker, Git, .env
- Створює мережу (якщо `AUTO_CREATE_NETWORK=true`)
- Генерує сертифікати (якщо `AUTO_GENERATE_CERTS=true`)
- Валідує конфігурацію Docker Compose

## Файл hosts

Відредагуйте `C:\Windows\System32\drivers\etc\hosts` з правами адміністратора:

```
127.0.0.1 traefik.home.arpa
127.0.0.1 demo.home.arpa
```

Для перегляду потрібних записів:

```powershell
.\scripts\show-hosts-entry.ps1
```

## DHCP reservation

Налаштуйте резервування IP-адреси для вашого комп'ютера в панелі керування роутера.

## Windows Firewall

Docker Desktop автоматично створює правила для портів. Якщо потрібен доступ з інших пристроїв:

1. Відкрийте `Windows Firewall with Advanced Security`.
2. Створіть правило для портів 80 та 443.
3. Дозвольте доступ лише для Private-мережі.

## PowerShell Execution Policy

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

## Конфлікти портів

Якщо порти 80 або 443 зайняті:
- Зупиніть IIS: `iisreset /stop`
- Зупиніть інші веб-сервери
- Або змініть порти в конфігурації Traefik

## Перевірка

```powershell
curl -I https://demo.home.arpa
curl -I https://traefik.home.arpa
```
