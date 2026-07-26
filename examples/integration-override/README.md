# Traefik Integration Override

Цей шаблон дозволяє підключити будь-який Docker-проєкт до Traefik без зміни оригінального `compose.yaml`.

## Як використовувати

1. Скопіюйте файли у директорію проєкту:

```bash
cp examples/integration-override/compose.traefik.override.yaml my-project/
cp examples/integration-override/.env.traefik.example my-project/.env.traefik
```

2. Відредагуйте `.env.traefik`:

```dotenv
APP_DOMAIN=myapp.home.arpa
APP_INTERNAL_PORT=8080
LOCAL_HOSTING_NETWORK=local-hosting
```

3. Запустіть з override:

```bash
docker compose -f compose.yaml -f compose.traefik.override.yaml --env-file .env.traefik up -d
```

## Переваги

- Не змінює оригінальний `compose.yaml` проєкту.
- Безпечний для чужих проєктів з Git.
- Можна легко вимкнути інтеграцію.

## Автоматична генерація

```powershell
.\scripts\add-project.ps1 -ProjectPath ".\my-project" -Domain "myapp.home.arpa" -Service "web" -InternalPort 8080
```
