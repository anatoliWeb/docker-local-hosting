# HTTPS та сертифікати

## Що таке mkcert

[mkcert](https://github.com/FiloSottile/mkcert) — це інструмент для створення локально довірених TLS-сертифікатів. Він створює локальний центр сертифікації (CA) і додає його в довірені кореневі центри вашої системи.

## Локальний CA

При першому запуску `mkcert -install` створюється локальний CA:
- Приватний ключ CA: `rootCA-key.pem` — зберігається в системному каталозі, визначеному `mkcert -CAROOT`.
- Сертифікат CA: `rootCA.pem` — встановлюється в довірені кореневі центри.

**Ніколи не копіюйте `rootCA-key.pem` на інші комп'ютери.**

## Створення сертифіката

```powershell
mkcert -cert-file certs/home.arpa.pem -key-file certs/home.arpa-key.pem home.arpa "*.home.arpa"
```

або через скрипт:
```powershell
.\scripts\generate-certs.ps1
```

### Wildcard

`*.home.arpa` покриває:
- `demo.home.arpa`
- `traefik.home.arpa`
- `crm.home.arpa`

**Не покриває:**
- `api.crm.home.arpa` (вкладений піддомен)

### Вкладені піддомени

Стандартний wildcard `*.*.home.arpa` не підтримується більшістю інструментів, включаючи mkcert.

Для вкладених піддоменів є два варіанти:
1. **Однорівневі домени**: `crm-api.home.arpa` замість `api.crm.home.arpa`.
2. **Сертифікат з конкретними SAN**: додайте всі потрібні домени в команду mkcert.

### SAN (Subject Alternative Name)

Якщо потрібно багато доменів:
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

- Приватні ключі (`*-key.pem`) додані в `.gitignore`.
- Файли сертифікатів (`*.pem`) також в `.gitignore`.
- CA private key (`rootCA-key.pem`) знаходиться в системному каталозі, його не потрібно додавати в Git.
