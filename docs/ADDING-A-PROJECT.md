# Додавання нового проєкту

## Як це працює

Центральний Traefik автоматично знаходить нові контейнери через Docker Socket Proxy. Єдина вимога — ваш контейнер має бути підключений до зовнішньої мережі `local-hosting` та мати відповідні Traefik labels.

## Спосіб 1: Шаблон проєкту (рекомендовано)

```bash
cp -r examples/project-template projects/myapp
```

Змініть `MYAPP_HOST` у `projects/myapp/.env` та запустіть:

```bash
docker compose -f projects/myapp/compose.yaml up -d
```

## Спосіб 2: Вручну

### Крок 1: Додайте мережу до вашого compose.yaml

```yaml
networks:
  local-hosting:
    external: true
    name: ${LOCAL_HOSTING_NETWORK:-local-hosting}
```

### Крок 2: Додайте Traefik labels до вашого сервісу

```yaml
services:
  app:
    image: nginx:stable-alpine
    networks:
      - ${LOCAL_HOSTING_NETWORK:-local-hosting}
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.myapp.rule=Host(`myapp.home.arpa`)"
      - "traefik.http.routers.myapp.entrypoints=websecure"
      - "traefik.http.routers.myapp.tls=true"
      - "traefik.http.services.myapp.loadbalancer.server.port=80"
```

### Крок 3: Додайте домен у hosts

```powershell
.\scripts\show-hosts-entry.ps1 myapp.home.arpa
```

Або вручну в файл hosts (від адміністратора):
```
127.0.0.1 myapp.home.arpa
```

### Крок 4: Запустіть проєкт

```bash
docker compose up -d
```

### Крок 5: Перевірте

```bash
curl -I https://myapp.home.arpa
```

### Крок 6: Валідація проєкту

```bash
.\scripts\check-project.ps1 .\projects\myapp
```

## Зупинка та видалення маршруту

```bash
docker compose down
```

Після зупинки контейнера Traefik автоматично видалить маршрут.

## Типові помилки

| Помилка | Причина | Вирішення |
|---------|---------|-----------|
| 404 | Неправильний Host | Перевірте `rule=Host()` |
| 502 | Недоступний бекенд | Перевірте `server.port` |
| 503 | Контейнер не ready | Перевірте healthcheck |
| Немає маршруту | `traefik.enable` не true | Додайте label |
| Неправильний домен | Відсутній hosts | Додайте запис у hosts |

## Повний приклад

Див. [examples/project-template/](../examples/project-template/).
