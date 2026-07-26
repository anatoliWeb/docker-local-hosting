# Політика безпеки

## Загальні правила

1. **Не комітьте `.env`** — файл містить конфігурацію серверів.
2. **Не комітьте приватні ключі** — файли `certs/*.pem`, `certs/*.key` додані в `.gitignore`.
3. **Не комітьте `secrets/traefik-users`** — файл містить hash пароля Dashboard. Доданий в `.gitignore`.
4. **Не публікуйте Traefik Dashboard в інтернет** — він призначений лише для локальної мережі.
5. **Не копіюйте CA private key на клієнтські ПК** — копіюйте лише сертифікат CA (rootCA.pem).
6. **Не використовуйте це як production-рішення** — без додаткового hardening це небезпечно.
7. **Регулярно оновлюйте Docker-образи** — слідкуйте за security advisories.

## Архітектурна безпека

- Traefik не має прямого доступу до Docker socket — використовується Docker Socket Proxy.
- Docker Socket Proxy підключений лише до внутрішньої мережі `traefik-socket`.
- Docker Socket Proxy має read-only доступ до Docker socket.
- Docker Socket Proxy дозволяє лише GET-запити (контейнери, мережі, сервіси).
- Docker Socket Proxy не дозволяє POST, PUT, DELETE запити.
- Traefik Dashboard захищений Basic Auth.
- `exposedByDefault` вимкнено — контейнери публікуються лише з `traefik.enable=true`.

## Windows Firewall

- Обмежте доступ до портів 80 та 443 лише для приватної мережі.
- Використовуйте профіль Private, а не Public.

## Повідомлення про вразливість

Якщо ви знайшли вразливість, створіть issue у репозиторії проєкту.
