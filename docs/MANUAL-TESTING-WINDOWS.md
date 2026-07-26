# Ручне тестування на Windows

Повний чекліст для перевірки `docker-local-hosting` на Windows 10/11.

## A. Передумови

- [ ] Windows 10 або 11
- [ ] Docker Desktop встановлений і запущений (`docker version`)
- [ ] Git встановлений (`git --version`)
- [ ] PowerShell 5.1+
- [ ] mkcert встановлений (`mkcert --version`)

### Що робити при помилці

- Docker Desktop: завантажте з https://www.docker.com/products/docker-desktop/
- Git: https://git-scm.com/
- mkcert: `winget install FiloSottile.mkcert`

## B. Підготовка

- [ ] Відкрийте PowerShell:

```powershell
Set-Location E:\_programming_\_project_\docker-local-hosting
```

- [ ] Перевірте автоматичне створення `.env`:

```powershell
.\scripts\ensure-env.ps1
```

- [ ] Перевірте, що .env ігнорується Git:

```powershell
git check-ignore -v .env
```

**Очікуваний результат:** Створено `.env` з `.env.example`. Повторний запуск
показує `Файл .env уже існує` і не змінює його.

## C. Basic Auth

- [ ] Запустіть скрипт генерації:

```powershell
.\scripts\generate-dashboard-auth.ps1
```

**Очікуваний результат:** Запит логіна і пароля. Пароль не відображається. Створено `secrets/traefik-users`.

- [ ] Перевірте, що secret ігнорується Git:

```powershell
git check-ignore -v secrets/traefik-users
```

**Очікуваний результат:** `secrets/traefik-users` (джерело: .gitignore)

- [ ] Перевірте, що .gitkeep і README.md не ігноруються:

```powershell
git check-ignore -v secrets/.gitkeep
git check-ignore -v secrets/README.md
```

**Очікуваний результат:** жодного виводу (файли не ігноруються)

**Що робити при помилці:** Якщо `secrets/traefik-users` не ігнорується — перевірте `.gitignore`.

## D. Сертифікати

- [ ] Встановіть локальний CA:

```powershell
mkcert -install
```

**Очікуваний результат:** `The local CA is now installed in the system trust store`

- [ ] Згенеруйте сертифікати:

```powershell
.\scripts\generate-certs.ps1
```

**Очікуваний результат:** `[OK] Сертифікати створено`

- [ ] Перевірте, що сертифікати ігноруються Git:

```powershell
git check-ignore -v certs/home.arpa.pem
git check-ignore -v certs/home.arpa-key.pem
```

**Очікуваний результат:** Файли ігноруються.

**Що робити при помилці:**

- `mkcert не знайдено`: встановіть `winget install FiloSottile.mkcert`
- Генерація не вдалася: перевірте, що .env містить правильні шляхи

## E. hosts

- [ ] Додайте домени в `C:\Windows\System32\drivers\etc\hosts` від імені адміністратора.

Знайдіть свій IPv4:

```powershell
(Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -eq "Ethernet" -or $_.InterfaceAlias -eq "Wi-Fi" }).IPAddress
```

Шаблон для hosts:

```text
127.0.0.1 demo.home.arpa
127.0.0.1 traefik.home.arpa
127.0.0.1 myapp.home.arpa
127.0.0.1 socket.home.arpa
```

**Очікуваний результат:** `ping demo.home.arpa` відповідає `127.0.0.1`.

**Що робити при помилці:** Запустіть блокнот від імені адміністратора, відкрийте файл hosts.

## F. Запуск

- [ ] Валідуйте Compose-файл:

```powershell
docker compose config
```

**Очікуваний результат:** Вивід YAML без помилок.

- [ ] Якщо stack ще не запущено, виконайте:

```powershell
.\start.ps1
```

**Очікуваний результат:** Контейнери запущено.

- [ ] Перевірте статус:

```powershell
docker compose ps
```

**Очікуваний результат:** Усі сервіси (bootstrap, traefik, docker-socket-proxy, demo) зі статусом `Up` або `Exited (0)` (bootstrap).

**Що робити при помилці:**
- `docker compose config` помилка: виконайте `docker compose config 2>&1`, виправте синтаксис
- Traefik не стартує: `docker compose logs traefik`

## G. Demo

- [ ] HTTP→HTTPS redirect:

```powershell
curl.exe -s -o NUL -w "%{http_code}" http://demo.home.arpa/
```

**Очікуваний результат:** `301`

- [ ] HTTPS без `-k` (довірений сертифікат):

```powershell
curl.exe -s -o NUL -w "%{http_code}" https://demo.home.arpa/
```

**Очікуваний результат:** `200`

- [ ] Браузер: відкрийте `https://demo.home.arpa`

**Очікуваний результат:** Сторінка без попередження про сертифікат.

**Що робити при помилці:**
- HTTP 301 → HTTPS 200 — це нормально
- SSL error: `mkcert -install` не виконано або CA не довірено
- 404/502: перевірте `docker compose logs demo`

## H. Dashboard

- [ ] Без credentials:

```powershell
curl.exe -s -o NUL -w "%{http_code}" https://traefik.home.arpa/dashboard/
```

**Очікуваний результат:** `401`

- [ ] З credentials (замініть `логін:пароль`):

```powershell
curl.exe -s -o NUL -w "%{http_code}" -u "логін:пароль" https://traefik.home.arpa/dashboard/
```

**Очікуваний результат:** `200` або redirect `302` на `/dashboard/`

- [ ] Браузер: відкрийте `https://traefik.home.arpa/dashboard/`

**Очікуваний результат:** З'являється вікно Basic Auth. Після логіну — Dashboard.

**Що робити при помилці:**
- 401 без credentials — очікувано
- 401 з credentials: перевірте `secrets/traefik-users` і `docker compose restart traefik`
- 404: перевірте `config/traefik/dynamic/dashboard.yaml`

## I. Docker hot discovery

- [ ] Зафіксуйте Traefik container ID:

```powershell
$traefikId = docker ps --filter "name=traefik" --format "{{.ID}}"
Write-Host $traefikId
```

- [ ] Запустіть project-template:

```powershell
cd examples\project-template
docker compose up -d
```

- [ ] Перевірте домен (додайте в hosts: `127.0.0.1 myapp.home.arpa`):

```powershell
curl.exe -s -o NUL -w "%{http_code}" --resolve "myapp.home.arpa:443:127.0.0.1" https://myapp.home.arpa/
```

**Очікуваний результат:** `200`

- [ ] Перевірте, що Traefik той самий:

```powershell
$newId = docker ps --filter "name=traefik" --format "{{.ID}}"
if ($traefikId -eq $newId) { Write-Host "OK: Traefik не перезапускався" } else { Write-Host "УВАГА: Traefik перезапущено" }
```

**Очікуваний результат:** ID однаковий.

- [ ] Зупиніть проект:

```powershell
docker compose down
```

- [ ] Перевірте зникнення маршруту (зачекайте 10-15 секунд):

```powershell
Start-Sleep -Seconds 15
curl.exe -s -o NUL -w "%{http_code}" --resolve "myapp.home.arpa:443:127.0.0.1" https://myapp.home.arpa/
```

**Очікуваний результат:** `404`

- [ ] Поверніться в корінь проєкту:

```powershell
cd E:\_programming_\_project_\docker-local-hosting
```

**Що робити при помилці:**
- 502 замість 200: контейнер не готовий, зачекайте 5-10 секунд
- 404 відразу після запуску: перевірте, чи правильно налаштовані лейбли
- Traefik ID змінився: перевірте `docker compose logs traefik`

## J. External service hot reload

- [ ] Зафіксуйте Traefik container ID (якщо змінився):

```powershell
$traefikId = docker ps --filter "name=traefik" --format "{{.ID}}"
```

- [ ] Додайте тестовий сервіс:

```powershell
.\scripts\add-external-service.ps1 -Name test-svc -Domain test.home.arpa -Url http://host.docker.internal:8080
```

**Очікуваний результат:** `[OK] Оновлено ... external-services.yaml`

- [ ] Перевірте router (зачекайте 5-10 секунд):

```powershell
curl.exe -s -o NUL -w "%{http_code}" --resolve "test.home.arpa:443:127.0.0.1" https://test.home.arpa/
```

**Очікуваний результат:** `502` (бекенд не існує, але маршрут створено)

- [ ] Змініть backend:

```powershell
.\scripts\add-external-service.ps1 -Name test-svc -Domain test.home.arpa -Url http://host.docker.internal:9090
```

**Очікуваний результат:** `[OK] Оновлено` без помилок

- [ ] Видаліть сервіс:

```powershell
.\scripts\remove-external-service.ps1 -Name test-svc -Force
```

**Очікуваний результат:** `[OK] Сервіс 'test-svc' видалено`

- [ ] Перевірте зникнення:

```powershell
Start-Sleep -Seconds 5
curl.exe -s -o NUL -w "%{http_code}" --resolve "test.home.arpa:443:127.0.0.1" https://test.home.arpa/
```

**Очікуваний результат:** `404`

- [ ] Перевірте, що Traefik ID не змінився:

```powershell
$newId = docker ps --filter "name=traefik" --format "{{.ID}}"
if ($traefikId -eq $newId) { Write-Host "OK: без restart" } else { Write-Host "УВАГА: Traefik перезапущено" }
```

**Очікуваний результат:** ID однаковий.

**Що робити при помилці:**
- 200 замість 502: бекенд випадково доступний
- 404 після додавання: зачекайте довше (до 30 секунд на Windows Desktop)
- Якщо hot reload не працює: `docker compose restart traefik` — це відомий fallback

## K. WebSocket

- [ ] Запустіть WebSocket demo:

```powershell
cd examples\websocket
docker compose up -d
```

- [ ] Перевірте HTTP:

```powershell
curl.exe -s -o NUL -w "%{http_code}" --resolve "socket.home.arpa:443:127.0.0.1" https://socket.home.arpa/
```

**Очікуваний результат:** `200`

- [ ] Зупиніть:

```powershell
docker compose down
cd E:\_programming_\_project_\docker-local-hosting
```

**Що робити при помилці:**
- 404/502: перевірте `docker compose logs ws-demo`
- Traefik не restart під час запуску прикладу — це нормально

## L. Stop/start

- [ ] Зупиніть сервіси:

```powershell
.\scripts\stop.ps1
```

**Очікуваний результат:** `[OK] Мережа 'local-hosting' збережена.`

- [ ] Перевірте, що мережа існує:

```powershell
docker network ls | Select-String "local-hosting"
```

**Очікуваний результат:** Мережа відображається.

- [ ] Запустіть знову:

```powershell
.\scripts\start.ps1
```

**Очікуваний результат:** Сервіси запущено.

**Що робити при помилці:**
- Мережа зникла: хтось виконав `docker compose down`, запустіть знову
- Traefik не стартує: `docker compose logs traefik`

## M. LAN (необов'язково)

- [ ] Якщо є другий ПК в локальній мережі:
  - Встановіть CA: скопіюйте `%LOCALAPPDATA%\mkcert\rootCA.pem` на другий ПК, встановіть як довірений кореневий
  - Додайте в hosts IP основного ПК з доменами
  - Перевірте: `curl.exe https://demo.home.arpa/`

- [ ] Якщо DNS сервер налаштовано:
  - Додайте A-записи для demo.home.arpa, traefik.home.arpa тощо

**Що робити при помилці:**
- SSL error: CA не встановлено на клієнті
- Connection refused: порти 80/443 не відкриті в Windows Firewall

## N. Git audit

- [ ] Перевірте статус:

```powershell
Set-Location E:\_programming_\_project_\docker-local-hosting
git status --short --untracked-files=all
```

- [ ] Перевірте .env:

```powershell
git check-ignore -v .env
```

- [ ] Перевірте private key:

```powershell
git check-ignore -v certs/home.arpa-key.pem
```

- [ ] Перевірте secrets:

```powershell
git check-ignore -v secrets/traefik-users
```

- [ ] Перевірте, що dashboard.yaml не містить hardcoded hash:

```powershell
Get-Content config/traefik/dynamic/dashboard.yaml
```

**Очікуваний результат:** `usersFile: /run/secrets/traefik-users` (не `users:`)

**Що робити при помилці:** Якщо щось не ігнорується — оновіть `.gitignore`.

## O. Готовність до commit

- [ ] Trusted HTTPS працює без `-k`
- [ ] Dashboard: 401 без логіну, 200 з логіном
- [ ] Docker hot discovery: новий контейнер = новий маршрут без restart
- [ ] File Provider: оновлення external-services.yaml без recreate Traefik
- [ ] Secrets (secrets/traefik-users) ігноруються Git
- [ ] .env ігнорується Git
- [ ] Немає `:latest` образів
- [ ] Немає test-файлів
- [ ] Немає test-контейнерів
- [ ] Документація відповідає коду
