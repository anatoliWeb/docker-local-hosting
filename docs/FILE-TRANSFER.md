# Передача файлів

## FTP

Класичний FTP має дві проблеми для проксі через Traefik:

1. **Control + Data connections**: FTP використовує окремий порт для команд (21) і
   окремі порти для даних (активний або пасивний режим).
2. **Passive FTP**: Потребує діапазону портів для даних.

FTP/FTPS незручно проксувати універсально через Traefik.

## SFTP (рекомендовано)

SFTP (SSH File Transfer Protocol) працює через один TCP-порт (22).
Він використовує SSH для автентифікації та шифрування.

### Переваги SFTP

- Один порт (22/TCP).
- Вбудоване шифрування.
- Не потребує окремих data портів.
- Стандартний SSH-клієнт на всіх платформах.

### SFTP через Traefik

```yaml
services:
  sftp:
    image: atmoz/sftp:debian-9
    restart: unless-stopped
    networks:
      - local-hosting
    labels:
      - "traefik.enable=true"
      - "traefik.tcp.routers.sftp.rule=HostSNI(`*`)"
      - "traefik.tcp.routers.sftp.entrypoints=sftp"
      - "traefik.tcp.services.sftp.loadbalancer.server.port=22"
```

**Вимоги:**
1. Додати entrypoint `sftp` у `config/traefik/traefik.yaml`.
2. Опублікувати порт 22 у `compose.yaml`.
3. Перезапустити Traefik.

### Підключення

```bash
sftp user@sftp.home.arpa
```

## Висновок

Для локальної платформи рекомендовано SFTP.
Відкривайте SFTP лише за потреби.
