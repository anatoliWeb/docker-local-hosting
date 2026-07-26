<#
.SYNOPSIS
    Створює зовнішню Docker-мережу local-hosting, якщо вона ще не існує.
.DESCRIPTION
    Скрипт перевіряє наявність Docker, Docker daemon,
    перевіряє існування мережі local-hosting та створює її за потреби.
    Idempotent — безпечно запускати багаторазово.
.EXAMPLE
    .\scripts\create-network.ps1
#>

$ErrorActionPreference = "Stop"

# Перевірка наявності Docker
$dockerVersion = docker --version 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "ПОМИЛКА: Docker не знайдено. Встановіть Docker Desktop." -ForegroundColor Red
    exit 1
}
Write-Host "Docker знайдено: $dockerVersion" -ForegroundColor Green

# Перевірка Docker daemon
docker info 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "ПОМИЛКА: Docker daemon недоступний. Запустіть Docker Desktop." -ForegroundColor Red
    exit 1
}
Write-Host "Docker daemon працює." -ForegroundColor Green

# Перевірка існування мережі
$networkExists = docker network ls --format "{{.Name}}" 2>&1 | Select-String -Pattern "^local-hosting$" -SimpleMatch
if ($networkExists) {
    Write-Host "Мережа local-hosting вже існує. Нічого не змінено." -ForegroundColor Yellow
    exit 0
}

# Створення мережі
Write-Host "Створюю зовнішню Docker-мережу local-hosting..." -ForegroundColor Cyan
docker network create local-hosting --driver bridge --attachable
if ($LASTEXITCODE -ne 0) {
    Write-Host "ПОМИЛКА: Не вдалося створити мережу local-hosting." -ForegroundColor Red
    exit 1
}

Write-Host "Мережа local-hosting успішно створена." -ForegroundColor Green
Write-Host "Тепер ви можете запустити основний проєкт: docker compose up -d" -ForegroundColor Cyan
exit 0
