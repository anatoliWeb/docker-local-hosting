# Проєкт у docker-local-hosting

## Опис

Це шаблон для швидкого додавання нового проєкту в екосистему Docker Local Hosting.
Скопіюйте директорію, змініть назву сервісу та домен — і ваш сервіс отримає HTTPS.

## Підключення до docker-local-hosting

1. **Скопіюйте шаблон:**
   ```bash
   cp -r examples/project-template projects/myapp
   ```

2. **Налаштуйте .env:**
   ```
   MYAPP_HOST=myapp.home.arpa
   ```

3. **Додайте домен у hosts:**
   - Windows (адміністратор): `127.0.0.1 myapp.home.arpa` у `C:\Windows\System32\drivers\etc\hosts`
   - Linux: `sudo sh -c 'echo "127.0.0.1 myapp.home.arpa" >> /etc/hosts'`

4. **Запустіть:**
   ```bash
   docker compose -f compose.yaml up -d
   ```

5. **Відкрийте:** `https://myapp.home.arpa`

## Вимоги

- Мережа `local-hosting` має існувати (створюється `scripts/setup.ps1`/`.sh`)
- Сертифікати для `*.home.arpa` мають бути згенеровані (через `scripts/generate-certs.ps1`/`.sh`)
- Docker Local Hosting має бути запущений (щоб Traefik працював)

## Змінні оточення

| Змінна       | За замовчуванням    | Опис                |
|-------------|---------------------|---------------------|
| `MYAPP_HOST` | `myapp.home.arpa`   | Домен застосунку   |
