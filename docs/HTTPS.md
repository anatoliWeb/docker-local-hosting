# HTTPS та сертифікати

## mkcert

[mkcert](https://github.com/FiloSottile/mkcert) створює локально довірені TLS-сертифікати.
CA встановлюється на хості, не в контейнері.

**Ніколи не копіюйте `rootCA-key.pem` на інші комп'ютери.**

## Одноразова підготовка

```powershell
winget install FiloSottile.mkcert
mkcert -install
```

Або:
```powershell
.\scripts\install-prerequisites.ps1
```

## Генерація сертифіката

```powershell
.\scripts\generate-certs.ps1
```

Скрипт читає:
- `TLS_CERT_FILE` — шлях до cert.pem
- `TLS_KEY_FILE` — шлях до key.pem
- `MKCERT_DOMAINS` — домени

### Поведінка

1. Перевіряє mkcert.
2. Якщо сертифікати дійсні (>30 днів) — пропускає.
3. Якщо прострочені — бекап + генерація.

## Bootstrap TLS

При `docker compose up -d`:
1. Bootstrap сервіс перевіряє cert та key.
2. Якщо файлів немає — показує помилку.
3. Traefik не запуститься без успішного bootstrap.

## Wildcard

`*.home.arpa` покриває однорівневі піддомени.
Не покриває вкладені (`api.crm.home.arpa`).

### Рішення
1. Однорівневі домени: `crm-api.home.arpa`
2. SAN: `mkcert ... "api.crm.home.arpa" "admin.crm.home.arpa"`

## CA на клієнтських ПК

```powershell
mkcert -CAROOT  # знайти rootCA.pem
```
Встановіть `rootCA.pem` на клієнтському ПК як довірений кореневий CA.

## Оновлення

```powershell
.\scripts\generate-certs.ps1
docker compose restart traefik
```
