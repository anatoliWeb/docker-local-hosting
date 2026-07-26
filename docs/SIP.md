# SIP та VoIP

## Обмеження поточної платформи

SIP-телефонія — це складний протокол, який виходить за межі простого HTTP/HTTPS проксі.
Поточна платформа docker-local-hosting надає **лише базовий signaling приклад**.

### Що не працює "з коробки"

| Компонент | Статус | Причина |
|-----------|--------|---------|
| SIP signaling (5060 UDP/TCP) | Обмежено | Потребує окремих entrypoints |
| SIP TLS (5061 TCP) | Потребує налаштування | Окремий entrypoint |
| RTP media (audio/video) | НЕ ПРАЦЮЄ | Динамічний діапазон портів |
| NAT traversal | НЕ ПРАЦЮЄ | SDP містить private IP |
| WebRTC | Потребує TURN | Окремий сервер |

### RTP

RTP використовує окремий UDP port range (наприклад, 10000-20000).
Traefik не може динамічно проксувати діапазон UDP-портів для RTP.
Для повної телефонії потрібен окремий медіа-сервер (RTPEngine, MediaProxy).

### SIP ALG

Деякі роутери мають SIP ALG (Application Layer Gateway),
який може змінювати SIP-пакети. Рекомендується вимкнути SIP ALG на роутері.

## Профіль

Див. [profiles/udp/sip-signaling.compose.example.yaml](../profiles/udp/sip-signaling.compose.example.yaml)
для базового signaling прикладу.

## Рекомендації

- Для локальної SIP-телефонії розгляньте виділений Asterisk/FreePBX сервер.
- Для WebRTC потрібен TURN/STUN сервер (coturn).
- Не використовуйте цю платформу для production VoIP без додаткового налаштування.
- NAT, SDP і SIP ALG можуть створювати проблеми з'єднання.
- Конкретний діапазон RTP залежить від Asterisk/FreePBX/Kamailio.
