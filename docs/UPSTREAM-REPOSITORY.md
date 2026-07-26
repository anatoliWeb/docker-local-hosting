# Upstream-репозиторії

Цей проєкт створено на основі архітектурних референсів із таких відкритих репозиторіїв:

## Досліджені репозиторії

### 1. BretFisher/compose-dev-tls
- **Автор**: Bret Fisher
- **URL**: https://github.com/BretFisher/compose-dev-tls
- **Ліцензія**: Unlicense
- **Останній commit**: 2020
- **Зірки**: ~134
- **Використано**: Архітектурний референс для Traefik + Docker Compose + локальний TLS.
- **Статус**: Активність припинена, але архітектура залишається релевантною.

### 2. traefik/traefik
- **Автор**: Traefik Labs
- **URL**: https://github.com/traefik/traefik
- **Ліцензія**: MIT
- **Остання версія**: v3.7.9 (липень 2026)
- **Зірки**: ~64k
- **Використано**: Офіційна документація Traefik v3 як основа конфігурації.
- **Статус**: Активно підтримується.

### 3. Tecnativa/docker-socket-proxy
- **Автор**: Tecnativa
- **URL**: https://github.com/Tecnativa/docker-socket-proxy
- **Ліцензія**: Apache 2.0
- **Остання версія**: v0.4.2 (грудень 2025)
- **Зірки**: ~2.6k
- **Використано**: Docker Socket Proxy як компонент безпеки.
- **Статус**: Активно підтримується.

## Вибір основи

Проєкт не копіює код жодного з перелічених репозиторіїв напряму.

Натомість використано:
- Архітектурний патерн Traefik + Docker Socket Proxy + mkcert (поширений у спільноті).
- Конкретні рішення з адаптацією під Windows, українську документацію та локальну доменну зону `home.arpa`.

## Що створено самостійно

- `compose.yaml` — повністю власна реалізація.
- `config/traefik/traefik.yaml` — власна статична конфігурація Traefik v3.
- `config/traefik/dynamic/tls.yaml` — власна TLS-конфігурація.
- Усі скрипти PowerShell та shell (`scripts/`).
- Демонстраційний сайт, приклади, документація.
- README, SECURITY, LICENSE.

## Copyright notices

Усі третій-сторонні компоненти (Traefik, Docker Socket Proxy, Nginx) використовуються як готові Docker-образи з їхніми оригінальними ліцензіями.
