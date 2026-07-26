<#
.SYNOPSIS
    Повністю видаляє центральні сервіси, мережу та образи.
.DESCRIPTION
    Виконує docker compose down --volumes --rmi all, що видаляє контейнери,
    мережу та образи. НЕ видаляє .env, сертифікати, secrets.
    Вимагає підтвердження. Перевіряє сторонні контейнери в мережі.
.EXAMPLE
    .\scripts\destroy.ps1
#>

$ErrorActionPreference = "Stop"
$rootDir = Resolve-Path -Path "$PSScriptRoot\.."

Write-Host "================================================" -ForegroundColor Red
Write-Host "  Docker Local Hosting - ПОВНЕ ВИДАЛЕННЯ" -ForegroundColor Red
Write-Host "================================================" -ForegroundColor Red
Write-Host ""

$networkName = "local-hosting"
$netExists = docker network ls --format "{{.Name}}" 2>&1 | Select-String -Pattern "^$networkName$"
if ($netExists) {
    $connected = docker network inspect $networkName --format "{{range .Containers}}{{.Name}} {{end}}" 2>$null
    if ($connected) {
        Write-Host "[УВАГА] До мережі '$networkName' підключені:" -ForegroundColor Yellow
        $connected.Split(" ", [StringSplitOptions]::RemoveEmptyEntries) | ForEach-Object {
            Write-Host "  - $_" -ForegroundColor Yellow
        }
        Write-Host "Після видалення мережі ці контейнери втратять з'єднання." -ForegroundColor Yellow
        Write-Host ""
    }
}

Write-Host "Буде видалено:" -ForegroundColor Red
Write-Host "  - контейнери (bootstrap, traefik, docker-socket-proxy, demo)" -ForegroundColor Red
Write-Host "  - мережу local-hosting" -ForegroundColor Red
Write-Host "  - внутрішню мережу traefik-socket" -ForegroundColor Red
Write-Host "  - Docker-образи центральних сервісів" -ForegroundColor Red
Write-Host ""
Write-Host "Залишиться:" -ForegroundColor Green
Write-Host "  - .env" -ForegroundColor Green
Write-Host "  - Сертифікати (certs/)" -ForegroundColor Green
Write-Host "  - Secrets (secrets/)" -ForegroundColor Green
Write-Host ""

$response = Read-Host "Видалити всі центральні сервіси? (Y/N)"
if ($response -ne "Y" -and $response -ne "y") { Write-Host "Скасовано." -ForegroundColor Yellow; exit 0 }

Write-Host ""
Write-Host "Видалення..." -ForegroundColor Yellow
Set-Location $rootDir

docker compose down --volumes --rmi all

Write-Host ""
Write-Host "[OK] Центральні сервіси видалено." -ForegroundColor Green
Write-Host ""
Write-Host "Для повторного налаштування:" -ForegroundColor Cyan
Write-Host "  .\scripts\install-prerequisites.ps1" -ForegroundColor Cyan
Write-Host "  .\scripts\generate-dashboard-auth.ps1" -ForegroundColor Cyan
Write-Host "  .\scripts\generate-certs.ps1" -ForegroundColor Cyan
Write-Host "  .\scripts\start.ps1" -ForegroundColor Cyan
