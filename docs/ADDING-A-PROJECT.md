# Додавання нового проєкту

Traefik автоматично знаходить нові контейнери в мережі `local-hosting`.
Перезапуск Traefik не потрібен.

## Спосіб 1: Generator override (рекомендовано)

```powershell
.\scripts\add-project.ps1 -ProjectPath ".\my-project" -Domain "myapp.home.arpa" -Service "web" -InternalPort 8080
```

Створює:
- `compose.traefik.override.yaml` — Traefik labels + мережа
- `.env.traefik` — змінні оточення

Запуск:
```powershell
docker compose -f compose.yaml -f compose.traefik.override.yaml --env-file .env.traefik up -d
```

Переваги: не змінює оригінальний compose.yaml проєкту.

## Спосіб 2: Шаблон проєкту

```bash
cp -r examples/project-template projects/myapp
```

Змініть `MYAPP_HOST` та запустіть:
```bash
docker compose -f projects/myapp/compose.yaml up -d
```

## Спосіб 3: Вручну

```yaml
services:
  app:
    image: nginx:1.27-alpine
    networks:
      - ${LOCAL_HOSTING_NETWORK:-local-hosting}
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.myapp.rule=Host(`myapp.home.arpa`)"
      - "traefik.http.routers.myapp.entrypoints=websecure"
      - "traefik.http.routers.myapp.tls=true"
      - "traefik.http.services.myapp.loadbalancer.server.port=80"

networks:
  local-hosting:
    external: true
    name: ${LOCAL_HOSTING_NETWORK:-local-hosting}
```

## Домен

Домен задається через `.env`:
```dotenv
APP_DOMAIN=myapp.home.arpa
```

Helper не публікує контейнер без явної згоди.

## Порт

Якщо image має один EXPOSE, Traefik може використати його автоматично.
Але рекомендовано задавати порт явно:
```yaml
traefik.http.services.myapp.loadbalancer.server.port: "${APP_INTERNAL_PORT:-8080}"
```

## Валідація проєкту

```powershell
.\scripts\check-project.ps1 .\projects\myapp
```

Покаже:
- наявність labels;
- мережу;
- `АВТОВИЗНАЧЕННЯ БЕЗПЕЧНЕ` або `ПОТРIБНО ВКАЗАТИ APP_INTERNAL_PORT`.

## Hosts

```powershell
.\scripts\show-hosts-entry.ps1 myapp.home.arpa
```

## Типові помилки

| Помилка | Причина | Вирішення |
|---------|---------|-----------|
| 404 | Неправильний Host | Перевірте `rule=Host()` |
| 502 | Недоступний бекенд | Перевірте `server.port` |
| 503 | Контейнер не ready | Перевірте healthcheck |
| Немає маршруту | `traefik.enable` не true | Додайте label |
| 401 | Немає auth | Додайте Basic Auth |

## Посилання

- [project-template](../examples/project-template/)
- [integration-override](../examples/integration-override/)
- [HTTPS.md](HTTPS.md)
