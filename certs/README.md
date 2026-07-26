# Сертифікати

Цей каталог містить TLS-сертифікати для локальних доменів `home.arpa`.

## Як згенерувати сертифікати

```powershell
.\scripts\generate-certs.ps1
```

або вручну:

```powershell
mkcert -cert-file certs/home.arpa.pem -key-file certs/home.arpa-key.pem home.arpa *.home.arpa
```

## Важливо

- Файли `.pem` та `.key` додані в `.gitignore` — вони не потраплять у Git.
- Приватний ключ (`*-key.pem`) нікому не передавайте.
- CA-ключ (`rootCA-key.pem`) знаходиться в системному каталозі mkcert — не копіюйте його на інші комп'ютери.
- Wildcard `*.home.arpa` не покриває вкладені піддомени на кшталт `api.crm.home.arpa`.
