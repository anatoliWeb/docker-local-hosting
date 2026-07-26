# Додавання нового проєкту

## Як це працює

Центральний Traefik автоматично знаходить нові контейнери через Docker Socket Proxy. Єдина вимога — ваш контейнер має бути підключений до зовнішньої мережі `local-hosting` та мати відповідні Traefik labels.

## Крок 1: Додайте мережу до вашого compose.yaml

```yaml
networks:
  local-hosting:
    external: true
```

## Крок 2: Додайте Traefik labels до вашого сервісу

```yaml
services:
  app:
    image: nginx:stable-alpine
    networks:
      - local-hosting
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.myapp.rule=Host(`myapp.home.arpa`)"
      - "traefik.http.routers.myapp.entrypoints=websecure"
      - "traefik.http.routers.myapp.tls=true"
      - "traefik.http.services.myapp.loadbalancer.server.port=80"
```

### Як називати router

- Унікальне ім'я в межах усього Traefik.
- Використовуйте назву проєкту: `myapp`, `crm`, `blog`.

### Як називати service

- Так само унікальне ім'я.
- Зазвичай збігається з назвою router: `myapp`.

### internal port

Вкажіть порт, на якому ваш контейнер слухає всередині. Не плутайте з `ports:`.

### Чому `ports` не потрібні

Traefik працює через внутрішню Docker-мережу. Якщо контейнер має labels та підключений до `local-hosting`, Traefik сам знайде його і направить трафік. `ports:` потрібні лише якщо потрібен прямий доступ до контейнера без Traefik.

## Крок 3: Додайте домен у hosts

Відредагуйте файл hosts з правами адміністратора:
```
192.168.1.100 myapp.home.arpa
```

## Крок 4: Запустіть проєкт

```bash
docker compose up -d
```

## Крок 5: Перевірте

```bash
curl -I https://myapp.home.arpa
```

Відкрийте в браузері `https://myapp.home.arpa`.

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

Див. [examples/basic-container.compose.example.yaml](../examples/basic-container.compose.example.yaml).
