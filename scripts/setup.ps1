<#
.SYNOPSIS
    Налаштовує та перевіряє середовище docker-local-hosting.
.DESCRIPTION
    Скрипт виконує повну перевірку готовності системи до запуску
    локального Docker-хостингу: перевіряє Git, Docker, .env,
    мережу, сертифікати та надає інструкції.
.EXAMPLE
    .\scripts\setup.ps1
#>

$ErrorActionPreference = "Stop"
$rootDir = Resolve-Path -Path "$PSScriptRoot\.."

function Write-Step {
    param([string]$message)
    Write-Host ""
    Write-Host "==> $message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$message)
    Write-Host "[OK] $message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$message)
    Write-Host "[УВАГА] $message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$message)
    Write-Host "[ПОМИЛКА] $message" -ForegroundColor Red
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Docker Local Hosting — налаштування" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# 1. Git
Write-Step "1. Перевірка Git"
$gitVersion = git --version 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Success "Git знайдено: $gitVersion"
} else {
    Write-Warning "Git не знайдено. Для роботи з репозиторієм встановіть Git."
}

# 2. Docker
Write-Step "2. Перевірка Docker"
$dockerVersion = docker --version 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Success "Docker знайдено: $dockerVersion"
} else {
    Write-Error "Docker не знайдено. Встановіть Docker Desktop."
    exit 1
}

# 3. Docker daemon
Write-Step "3. Перевірка Docker daemon"
docker info 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Success "Docker daemon працює."
} else {
    Write-Error "Docker daemon недоступний. Запустіть Docker Desktop."
    exit 1
}

# 4. Docker Compose
Write-Step "4. Перевірка Docker Compose"
$composeVersion = docker compose version 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Success "Docker Compose знайдено: $composeVersion"
} else {
    Write-Error "Docker Compose не знайдено. Оновіть Docker Desktop."
    exit 1
}

# 5. .env
Write-Step "5. Перевірка .env"
$envFile = Join-Path -Path $rootDir -ChildPath ".env"
$envExample = Join-Path -Path $rootDir -ChildPath ".env.example"
if (Test-Path -Path $envFile) {
    Write-Success "Файл .env існує."
} else {
    Write-Warning "Файл .env відсутній."
    if (Test-Path -Path $envExample) {
        Write-Host "  Створюю .env із .env.example..." -ForegroundColor Yellow
        Copy-Item -Path $envExample -Destination $envFile
        Write-Success "Файл .env створено з .env.example."
        Write-Host "  Відредагуйте .env за потреби (особливо TRAEFIK_BASIC_AUTH)." -ForegroundColor Yellow
    } else {
        Write-Error "Файл .env.example також відсутній. Проєкт пошкоджено."
        exit 1
    }
}

# 6. Мережа local-hosting
Write-Step "6. Перевірка мережі local-hosting"
$networkExists = docker network ls --format "{{.Name}}" 2>&1 | Select-String -Pattern "^local-hosting$" -SimpleMatch
if ($networkExists) {
    Write-Success "Мережа local-hosting існує."
} else {
    Write-Warning "Мережа local-hosting відсутня."
    Write-Host "  Створюю мережу local-hosting..." -ForegroundColor Yellow
    docker network create local-hosting --driver bridge --attachable
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Мережу local-hosting створено."
    } else {
        Write-Error "Не вдалося створити мережу."
        exit 1
    }
}

# 7. Сертифікати
Write-Step "7. Перевірка сертифікатів"
$certFile = Join-Path -Path $rootDir -ChildPath "certs\home.arpa.pem"
$keyFile = Join-Path -Path $rootDir -ChildPath "certs\home.arpa-key.pem"
if ((Test-Path $certFile) -and (Test-Path $keyFile)) {
    Write-Success "Сертифікати знайдено:"
    Write-Host "  Сертифікат: $certFile" -ForegroundColor Green
    Write-Host "  Ключ: $keyFile" -ForegroundColor Green
} else {
    Write-Warning "Сертифікати не знайдено."
    Write-Host "  Згенеруйте їх командою:" -ForegroundColor Yellow
    Write-Host "    .\scripts\generate-certs.ps1" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Або вручну через mkcert:" -ForegroundColor Yellow
    Write-Host "    mkcert -cert-file certs/home.arpa.pem -key-file certs/home.arpa-key.pem home.arpa *.home.arpa" -ForegroundColor Yellow
}

# 8. Перевірка конфігурації Compose
Write-Step "8. Перевірка конфігурації Docker Compose"
$composeConfig = docker compose config 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Success "Конфігурація Docker Compose валідна."
} else {
    Write-Error "Помилка валідації конфігурації:"
    Write-Host $composeConfig -ForegroundColor Red
    exit 1
}

# Підсумок
Write-Step "Підсумок"
Write-Host "Налаштування завершено." -ForegroundColor Green
Write-Host ""
Write-Host "Запустіть проєкт командою:" -ForegroundColor Cyan
Write-Host "  docker compose up -d" -ForegroundColor Cyan
Write-Host ""
Write-Host "Перед запуском переконайтеся, що:" -ForegroundColor Yellow
Write-Host "  1. Файл hosts містить записи для доменів (від адміністратора)" -ForegroundColor Yellow
Write-Host "  2. mkcert CA встановлено: mkcert -install" -ForegroundColor Yellow
Write-Host "  3. Сертифікати згенеровано" -ForegroundColor Yellow
Write-Host ""
Write-Host "Докладніше: README.md" -ForegroundColor Cyan
exit 0
