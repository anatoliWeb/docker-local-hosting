# TCP профілі

Ці приклади показують, як публікувати TCP-сервіси через Traefik.

## Важливе обмеження

Новий HTTP router можна додати без restart Traefik, якщо entrypoint 80/443 уже існує.

Але новий TCP host port вимагає:
1. Додати entrypoint у static config (`traefik.yaml`).
2. Опублікувати host port у `compose.yaml`.
3. recreate/restart Traefik.

Це технічне обмеження Docker port binding і static Traefik configuration.

## SNI

TCP-маршрутизація за доменом можлива через TLS SNI.
Для незашифрованого raw TCP часто використовується `HostSNI(*)`.
Тоді один entrypoint зазвичай відповідає одному сервісу.

## Приклади

- `mqtt.compose.example.yaml` — MQTT без TLS та з TLS
- `sftp.compose.example.yaml` — SFTP через TCP
- `raw-tcp.compose.example.yaml` — Raw TCP сервіс
