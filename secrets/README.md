# Секрети

Цей каталог містить локальні секрети, які не комітяться в Git:
- 	raefik-users — файл користувачів для Basic Auth Dashboard (user:hash)

## Безпека

- Файли в secrets/ додані в .gitignore
- Не зберігайте тут паролі в відкритому вигляді
- Використовуйте .\scripts\generate-dashboard-auth.ps1 для створення secrets/traefik-users

