<#
.SYNOPSIS
    Створює secrets/traefik-users для Basic Auth Dashboard.
.DESCRIPTION
    Запитує логін і пароль, генерує bcrypt hash через Docker httpd,
    записує у secrets/traefik-users. Перевіряє, що файл ігнорується Git.
.EXAMPLE
    .\scripts\generate-dashboard-auth.ps1
#>

$ErrorActionPreference = "Stop"
$rootDir = Resolve-Path -Path "$PSScriptRoot\.."

$secretsDir = Join-Path $rootDir "secrets"
if (-not (Test-Path $secretsDir)) { New-Item -ItemType Directory -Path $secretsDir -Force | Out-Null }

Write-Host "Створення облікових даних для Traefik Dashboard" -ForegroundColor Cyan
Write-Host "Пароль не відображається на екрані." -ForegroundColor Yellow
Write-Host ""

$username = Read-Host "Логін (наприклад, admin)"
if ([string]::IsNullOrWhiteSpace($username)) { Write-Host "[ПОМИЛКА] Логін не може бути порожнім." -ForegroundColor Red; exit 1 }

$password = Read-Host "Пароль" -AsSecureString
$passwordPlain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password)
)
if ([string]::IsNullOrWhiteSpace($passwordPlain)) { Write-Host "[ПОМИЛКА] Пароль не може бути порожнім." -ForegroundColor Red; exit 1 }

$confirm = Read-Host "Повторіть пароль" -AsSecureString
$confirmPlain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($confirm)
)
if ($passwordPlain -ne $confirmPlain) { Write-Host "[ПОМИЛКА] Паролі не співпадають." -ForegroundColor Red; exit 1 }

Write-Host ""
Write-Host "Генерація bcrypt hash через Docker httpd:2.4.62-alpine..." -ForegroundColor Cyan
$hashOutput = docker run --rm httpd:2.4.62-alpine htpasswd -nbB $username $passwordPlain 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ПОМИЛКА] Не вдалося згенерувати hash: $hashOutput" -ForegroundColor Red
    exit 1
}
$hashLine = ($hashOutput | Where-Object { $_ -match ':' } | Select-Object -First 1).Trim()

$usersFile = Join-Path $secretsDir "traefik-users"
Set-Content -Path $usersFile -Value $hashLine -NoNewline

Write-Host "[OK] Файл $usersFile створено." -ForegroundColor Green

$gitCheck = git check-ignore -q $usersFile 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "[OK] Файл ігнорується Git." -ForegroundColor Green
} else {
    Write-Host "[УВАГА] Файл НЕ ігнорується Git. Перевірте .gitignore." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Підсумок:" -ForegroundColor Cyan
Write-Host "  Логін:   $username" -ForegroundColor Green
Write-Host "  Файл:    $usersFile (ігнорується Git)" -ForegroundColor Green
Write-Host ""
Write-Host "Dashboard буде доступний за адресою https://traefik.home.arpa/dashboard/" -ForegroundColor Cyan
Write-Host "Перезапустіть Traefik: docker compose restart traefik" -ForegroundColor Yellow
