# Приклади підключення

Цей каталог містить приклади налаштування Docker-проєктів для роботи з `docker-local-hosting`.

## Вміст

- `nginx-demo/` — демонстраційний сайт, який запускається разом із центральним проєктом.
- `project-template/` — шаблон для швидкого створення нового проєкту з HTTPS.
- `basic-container.compose.example.yaml` — шаблон підключення звичайного контейнера.
- `laravel.compose.example.yaml` — шаблон підключення Laravel-проєкту.

## Як використовувати

Для нового проєкту скопіюйте `project-template/`:

```bash
cp -r examples/project-template projects/myapp
```

Для одноразового підключення використовуйте `*.compose.example.yaml`:
```bash
cp examples/basic-container.compose.example.yaml my-project/compose.yaml
```
