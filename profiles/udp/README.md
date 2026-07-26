# UDP профілі

Ці приклади показують, як публікувати UDP-сервіси через Traefik.

## Важливе обмеження

UDP entrypoints вимагають:
1. Додати entrypoint у static config.
2. Опублікувати UDP host порт у Compose.
3. Перезапустити Traefik.

Traefik v3 підтримує UDP load balancing, але не всі протоколи
можуть коректно працювати через проксі (наприклад, SIP з RTP).

## Приклади

- `custom-udp.compose.example.yaml` — UDP сервіс
- `sip-signaling.compose.example.yaml` — SIP signaling (обмежений)
