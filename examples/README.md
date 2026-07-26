# Приклади підключення

## Вміст

- `nginx-demo/` — демонстраційний сайт.
- `project-template/` — шаблон нового проєкту.
- `integration-override/` — Traefik override (безпечне підключення).
- `websocket/` — WebSocket/WSS приклад.
- `basic-container.compose.example.yaml` — звичайний контейнер.
- `laravel.compose.example.yaml` — Laravel проєкт.

## Як використовувати

### Новий проєкт
```bash
cp -r examples/project-template projects/myapp
```

### Підключення через override (безпечно)
```bash
# Скопіюйте override шаблон
cp examples/integration-override/compose.traefik.override.yaml my-project/
cp examples/integration-override/.env.traefik.example my-project/.env.traefik

# Запустіть
docker compose -f compose.yaml -f compose.traefik.override.yaml --env-file .env.traefik up -d
```

### WebSocket demo
```bash
docker compose -f examples/websocket/compose.yaml up -d
```

### Автоматичний generator
```powershell
.\scripts\add-project.ps1 -ProjectPath ".\my-project" -Domain "myapp.home.arpa" -Service "web"
.\scripts\add-external-service.ps1 -Name camera -Domain camera.home.arpa -Url http://192.168.1.50:9000
```
