# WebSocket Demo

Приклад HTTP + WebSocket сервісу через Traefik.

## Запуск

```bash
docker compose -f compose.yaml up -d
```

Відкрийте:

- `https://socket.home.arpa` — HTML сторінка
- `wss://socket.home.arpa/ws` — WebSocket endpoint

## Як це працює

Traefik автоматично проксує WebSocket з'єднання через HTTP Upgrade.
Жодних додаткових middleware не потрібно.

## Важливо

- WebSocket працює через той самий порт 443.
- Traefik не потребує перезапуску для нового WebSocket сервісу.
- HTTP Upgrade заголовки передаються автоматично.
