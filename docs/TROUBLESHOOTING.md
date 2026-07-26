# Усунення проблем

## Docker Desktop не запущений
```
Помилка: Cannot connect to the Docker daemon
```
**Вирішення**: Запустіть Docker Desktop з меню Пуск.

## Docker daemon недоступний
```
Помилка: docker info повертає помилку з'єднання
```
**Вирішення**: Перевірте, чи працює Docker Engine. У треї має бути іконка Docker.

## Порт 80 зайнятий
```
Помилка: port is already allocated
```
**Вирішення**:
1. Перевірте, який процес займає порт: `netstat -ano | findstr :80`
2. Зупиніть конфліктуючий процес (IIS, Apache, Skype тощо).

## Порт 443 зайнятий
**Вирішення**: Аналогічно порту 80.

## Мережа local-hosting відсутня
```powershell
.\scripts\create-network.ps1
```
або
```bash
docker network create local-hosting --driver bridge --attachable
```

## .env відсутній
```powershell
Copy-Item .env.example .env
```

## Basic Auth неправильний

Переконайтеся, що hash створено правильно:
```bash
echo $(htpasswd -nb admin password) | sed -e 's/\$/\$\$/g'
```

Якщо `$` не екрановані, Docker Compose спробує інтерполювати їх як змінні.

## Сертифікат відсутній
```powershell
.\scripts\generate-certs.ps1
```

## Браузер не довіряє CA
```
Помилка: NET::ERR_CERT_AUTHORITY_INVALID
```
**Вирішення**: Встановіть CA-сертифікат:
```powershell
mkcert -install
```

## Домен не резолвиться
```
Помилка: DNS_PROBE_FINISHED_NXDOMAIN
```
**Вирішення**: Перевірте файл hosts. Домен має бути доданий вручну.

## hosts неправильний
- Кожен домен окремим рядком.
- Без зайвих символів.
- IP має збігатися з адресою Docker host.

## Traefik не бачить контейнер

1. Перевірте, чи контейнер має `traefik.enable=true`.
2. Перевірте, чи контейнер підключений до мережі `local-hosting`.
3. Перевірте, чи мережа `local-hosting` є зовнішньою.
4. Перевірте логи Traefik: `docker compose logs traefik`.

## Неправильна Docker network
Контейнер має бути в мережі `local-hosting`. Якщо він в іншій мережі, Traefik не зможе до нього звернутися.

## Неправильний internal port
```yaml
- "traefik.http.services.myapp.loadbalancer.server.port=80"
```
Порт має відповідати порту, на якому слухає ваш застосунок ВСЕРЕДИНІ контейнера.

## 404
- Неправильний Host у labels.
- Traefik не знає про такий маршрут.
- Перевірте `rule=Host()`.

## 502 Bad Gateway
- Контейнер працює, але не відповідає на вказаному порту.
- Перевірте `server.port`.
- Перевірте healthcheck контейнера.

## Unhealthy container
```bash
docker compose ps
docker compose logs demo
```
Перевірте логи проблемного контейнера.

## Windows Firewall
Якщо доступ з інших ПК не працює, перевірте правила Firewall.

## VPN
VPN може змінювати маршрутизацію. Тимчасово вимкніть VPN для перевірки.

## WSL
Docker Desktop на Windows використовує WSL. Якщо WSL не працює коректно, Docker може не стартувати.

## Docker Desktop networking
У налаштуваннях Docker Desktop переконайтеся, що мережа налаштована правильно. Використовуйте `docker network inspect local-hosting`.

## Прямий доступ працює, а домен ні
Якщо `curl http://localhost` працює, а `curl http://demo.home.arpa` ні — проблема в DNS/hosts.

## HTTPS працює лише з `curl -k`
```
curl: (60) SSL certificate problem: self-signed certificate
```
CA не встановлено в системі. Запустіть `mkcert -install`.
