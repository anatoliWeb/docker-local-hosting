# Налаштування на Windows

## Вимоги

- Windows 10 або 11
- Docker Desktop (остання версія)
- PowerShell 5.1 або новіший
- mkcert

## Встановлення Docker Desktop

1. Завантажте Docker Desktop з [docker.com](https://www.docker.com/products/docker-desktop/)
2. Встановіть, дотримуючись інструкцій
3. Після встановлення переконайтеся, що Docker Engine працює (іконка в треї)

## Встановлення mkcert

### Через winget (рекомендовано)
```powershell
winget install mkcert
```

### Через chocolatey
```powershell
choco install mkcert
```

### Вручну
1. Завантажте останній реліз з [github.com/FiloSottile/mkcert/releases](https://github.com/FiloSottile/mkcert/releases)
2. Виберіть `mkcert-v*-windows-amd64.exe`
3. Додайте його в PATH або покладіть у теку проєкту

## Створення локального CA
```powershell
mkcert -install
```

## Генерація сертифіката
```powershell
.\scripts\generate-certs.ps1
```

## Пошук IPv4-адреси
```powershell
ipconfig
```
Знайдіть адресу вашого інтерфейсу (наприклад, `192.168.1.100`).

## DHCP reservation (на роутері)
Налаштуйте резервування IP-адреси для вашого комп'ютера в панелі керування роутера.

## Файл hosts (від адміністратора)

Відредагуйте файл `C:\Windows\System32\drivers\etc\hosts` з правами адміністратора.

Додайте записи:
```
192.168.1.100 demo.home.arpa
192.168.1.100 traefik.home.arpa
```

Кожен новий домен потрібно додавати окремим рядком.

## Windows Firewall

Docker Desktop автоматично створює правила для портів. Якщо потрібен доступ з інших пристроїв:

1. Відкрийте `Windows Firewall with Advanced Security`
2. Створіть правило для портів 80 та 443
3. Дозвольте доступ лише для Private-мережі

## PowerShell Execution Policy
```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

## Перевірка портів
```powershell
netstat -ano | findstr :80
netstat -ano | findstr :443
```

## Конфлікти портів
Якщо порти 80 або 443 зайняті:
- Зупиніть IIS: `iisreset /stop`
- Зупиніть інші веб-сервери
- Або змініть порти в конфігурації Traefik

## Запуск
```powershell
.\scripts\setup.ps1
docker compose up -d
```

## Перевірка через браузер
Відкрийте `https://demo.home.arpa` та `https://traefik.home.arpa`.

## Перевірка через curl
```powershell
curl -I https://demo.home.arpa
curl -I https://traefik.home.arpa
```
