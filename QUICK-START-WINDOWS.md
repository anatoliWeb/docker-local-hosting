# Швидкий старт на Windows

```powershell
Set-Location E:\_programming_\_project_\docker-local-hosting
.\start.ps1
```

`start.ps1` є головною командою Windows. Під час першого запуску він створює
`.env` з `.env.example`, але ніколи не перезаписує наявний `.env`.

## Одноразова підготовка

1. Встановіть і запустіть Docker Desktop.
2. Встановіть mkcert та локальний CA:

```powershell
winget install FiloSottile.mkcert
mkcert -install
```

3. Створіть Basic Auth для Dashboard:

```powershell
.\scripts\generate-dashboard-auth.ps1
```

4. Створіть TLS-сертифікат:

```powershell
.\scripts\generate-certs.ps1
```

5. Додайте у `C:\Windows\System32\drivers\etc\hosts` від імені адміністратора:

```text
127.0.0.1 demo.home.arpa
127.0.0.1 traefik.home.arpa
```

## Запуск

```powershell
.\start.ps1
```

Або з `cmd.exe`:

```cmd
start.cmd
```

Після первинної підготовки можна запускати `docker compose up -d` напряму.
Ця команда не створює `.env`: автоматизацію забезпечує host-скрипт
`start.ps1` до запуску Docker Compose.

## Перевірка і зупинка

- `https://demo.home.arpa`
- `https://traefik.home.arpa/dashboard/`
- [Ручний чекліст](docs/MANUAL-TESTING-WINDOWS.md)

```powershell
.\scripts\stop.ps1
```
