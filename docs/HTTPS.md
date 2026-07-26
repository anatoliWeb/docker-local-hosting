# HTTPS та сертифікати

## Що таке mkcert

[mkcert](https://github.com/FiloSottile/mkcert) — інструмент для створення локально довірених TLS-сертифікатів. Він створює локальний центр сертифікації (CA) і додає його в довірені кореневі центри вашої системи.

## Локальний CA

При першому запуску `mkcert -install` створюється локальний CA:
- Приватний ключ CA: `rootCA-key.pem` — зберігається в системному каталозі.
- Сертифікат CA: `rootCA.pem` — встановлюється в довірені кореневі центри.

**Ніколи не копіюйте `rootCA-key.pem` на інші комп'ютери.**

## Створення сертифіката

```powershell
.\scripts\generate-certs.ps1
```

Скрипт читає змінні з `.env`:
- `TLS_CERT_FILE` — шлях до `cert.pem`
- `TLS_KEY_FILE` — шлях до `key.pem`
- `MKCERT_DOMAINS` — домени для сертифіката

### Поведінка скрипта

1. Перевіряє наявність mkcert.
2. Якщо сертифікати існують і дійсні (>30 днів) — пропускає генерацію.
3. Якщо сертифікати прострочені або пошкоджені — створює бекап старих файлів.
4. Генерує нові сертифікати.

### Ручна генерація

```powershell
mkcert -cert-file certs/home.arpa.pem -key-file certs/home.arpa-key.pem home.arpa "*.home.arpa"
```

## Змінні оточення для сертифікатів

| Змінна | За замовчуванням | Опис |
|--------|-----------------|------|
| `TLS_CERT_FILE` | `./certs/home.arpa.pem` | Шлях до сертифіката |
| `TLS_KEY_FILE` | `./certs/home.arpa-key.pem` | Шлях до ключа |
| `MKCERT_DOMAINS` | `home.arpa *.home.arpa` | Домени для mkcert |
| `AUTO_GENERATE_CERTS` | `true` | Авто-генерація в setup |

## Wildcard

`*.home.arpa` покриває:
- `demo.home.arpa`
- `traefik.home.arpa`
- `myapp.home.arpa`

**Не покриває:**
- `api.crm.home.arpa` (вкладений піддомен)

### Вкладені піддомени

Для вкладених піддоменів є два варіанти:
1. **Однорівневі домени**: `crm-api.home.arpa` замість `api.crm.home.arpa`.
2. **Сертифікат з конкретними SAN**: додайте всі потрібні домени в команду mkcert.

### SAN (Subject Alternative Name)

```powershell
mkcert -cert-file certs/home.arpa.pem -key-file certs/home.arpa-key.pem `
  "home.arpa" "*.home.arpa" "api.crm.home.arpa" "admin.crm.home.arpa"
```

## Встановлення довіри до CA

### Windows
```powershell
mkcert -install
```

### Linux
```bash
mkcert -install
```

### Інші комп'ютери в мережі
Див. [docs/LAN.md](LAN.md) — скопіюйте `rootCA.pem` та встановіть його як довірений кореневий сертифікат.

## Оновлення сертифіката

Якщо домени змінилися або сертифікат прострочився:
```powershell
.\scripts\generate-certs.ps1
docker compose restart traefik
```

## Видалення старого сертифіката

```powershell
Remove-Item certs/home.arpa.pem
Remove-Item certs/home.arpa-key.pem
```

## Захист ключів

- Сертифікати та ключі додані в `.gitignore`.
- CA private key (`rootCA-key.pem`) знаходиться в системному каталозі.
- Бекапи старих сертифікатів зберігаються в `certs/backup-*`.
