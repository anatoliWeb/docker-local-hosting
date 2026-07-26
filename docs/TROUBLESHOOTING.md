# Усунення проблем

## Bootstrap помилка: сертифікат не знайдено

```
bootstrap exited with code 1
```

**Вирішення**: Згенеруйте сертифікати:
```powershell
.\scripts\generate-certs.ps1
```

## Docker Desktop не запущений

```
Cannot connect to the Docker daemon
```
Запустіть Docker Desktop.

## Порт 80/443 зайнятий

```
port is already allocated
```
```powershell
netstat -ano | findstr :80
netstat -ano | findstr :443
```
Зупиніть конфліктуючий процес (IIS, Apache).

## Мережа local-hosting

Створюється автоматично при `docker compose up -d`.
Ручне створення: `docker network create local-hosting --driver bridge --attachable`.

## Dashboard 401

Неправильний Basic Auth. Перевірте `.env`:
```bash
echo $(htpasswd -nb admin password) | sed -e 's/\$/\$\$/g'
```

## Dashboard 404

Bootstrap не створив dashboard.yaml або auth не налаштовано.
Запустіть `.\scripts\setup.ps1` або `.\scripts\start.ps1`.

## Сертифікат не дійсний

```powershell
.\scripts\generate-certs.ps1
docker compose restart traefik
```

## Браузер не довіряє

```
NET::ERR_CERT_AUTHORITY_INVALID
```
```powershell
mkcert -install
```

## Traefik не бачить контейнер

1. `traefik.enable=true`?
2. Контейнер у мережі `local-hosting`?
3. `docker compose logs traefik`

## 404 на новому проєкті

Неправильний Host у labels. Перевірте `rule=Host()`.

## 502 Bad Gateway

Неправильний `server.port`. Контейнер не відповідає на вказаному порту.

## Домен не резолвиться

```
DNS_PROBE_FINISHED_NXDOMAIN
```
Додайте домен у файл hosts.

## curl тести (без hosts)

```powershell
curl.exe -sk -H "Host: demo.home.arpa" https://localhost/
curl.exe -sk -H "Host: traefik.home.arpa" https://localhost/
```
