<#
.SYNOPSIS
    Зупиняє центральні сервіси docker-local-hosting.
.DESCRIPTION
    Виконує docker compose stop і зберігає спільну мережу local-hosting.
.EXAMPLE
    .\scripts\stop.ps1
#>

$ErrorActionPreference = "Stop"
$rootDir = Resolve-Path -Path "$PSScriptRoot\.."

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  Docker Local Hosting — зупинка" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Зупинка сервісів..." -ForegroundColor Yellow

# Зупинка без видалення мережі
Set-Location $rootDir
docker compose stop
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ПОМИЛКА] Не вдалося зупинити сервіси." -ForegroundColor Red
    exit 1
}

# Перевірка, чи мережа все ще існує
Set-Location $rootDir
$netName = "local-hosting"
if (Get-Content .env -ErrorAction SilentlyContinue | Select-String '^LOCAL_HOSTING_NETWORK=') {
    $netName = (Get-Content .env | Where-Object { $_ -match '^LOCAL_HOSTING_NETWORK=(.+)$' } | ForEach-Object { $matches[1] })
}
$exists = docker network ls --format "{{.Name}}" 2>&1 | Select-String -Pattern "^$([regex]::Escape($netName))$"
if ($exists) {
    Write-Host "[OK] Мережа '$netName' збережена. Сторонні проєкти не зачеплено." -ForegroundColor Green
} else {
    Write-Host "[УВАГА] Мережа '$netName' відсутня." -ForegroundColor Yellow
}

Write-Host "[OK] Сервіси зупинено." -ForegroundColor Green
