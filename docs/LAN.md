# Доступ з інших комп'ютерів у локальній мережі

## Вимоги

- Центральний ПК з постійною IP (DHCP reservation).
- Порти 80/443 відкриті.
- Клієнтський ПК має доступ до центрального.

## Крок 1: Hosts на клієнтському ПК

### Windows
`C:\Windows\System32\drivers\etc\hosts` (адміністратор):
```
192.168.1.100 demo.home.arpa
192.168.1.100 traefik.home.arpa
```

### Linux / macOS
`/etc/hosts`:
```
192.168.1.100 demo.home.arpa
192.168.1.100 traefik.home.arpa
```

## Крок 2: CA-сертифікат на клієнтському ПК

На центральному ПК:
```powershell
mkcert -CAROOT
```
Скопіюйте `rootCA.pem` (НЕ `rootCA-key.pem`) на клієнтський ПК.

### Windows (клієнт)
Двічі клацніть `rootCA.pem` → Встановити сертифікат → Локальний комп'ютер → Довірені кореневі центри.

### Linux (клієнт)
```bash
sudo cp rootCA.pem /usr/local/share/ca-certificates/
sudo update-ca-certificates
```

### macOS (клієнт)
```bash
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain rootCA.pem
```

## Важливо

- НЕ копіюйте `rootCA-key.pem`.
- Для доступу з VPN тимчасово вимкніть VPN.
- Windows Firewall має дозволяти порти 80/443 для Private профілю.
