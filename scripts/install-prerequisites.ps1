<#
.SYNOPSIS
    Одноразова підготовка комп'ютера для docker-local-hosting.
.DESCRIPTION
    Встановлює mkcert, створює локальний CA, перевіряє Docker та Git.
    Не змінює систему без підтвердження.
.EXAMPLE
    .\scripts\install-prerequisites.ps1
#>

$ErrorActionPreference = "Stop"
$rootDir = Resolve-Path -Path "$PSScriptRoot\.."

function Write-Step { param([string]$m) Write-Host "`n==> $m" -ForegroundColor Cyan }
function Write-OK   { param([string]$m) Write-Host "[OK] $m" -ForegroundColor Green }
function Write-Warn { param([string]$m) Write-Host "[УВАГА] $m" -ForegroundColor Yellow }
function Write-Err  { param([string]$m) Write-Host "[ПОМИЛКА] $m" -ForegroundColor Red; exit 1 }

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  Docker Local Hosting — підготовка комп'ютера" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

Write-Step "1. Перевірка Git"
if (git --version 2>&1) { Write-OK "Git знайдено." }
else { Write-Warn "Git не знайдено. Встановіть: https://git-scm.com" }

Write-Step "2. Перевірка Docker"
$dv = docker --version 2>&1; if ($LASTEXITCODE -eq 0) { Write-OK "Docker: $dv" }
else { Write-Err "Docker не знайдено. Встановіть Docker Desktop." }

Write-Step "3. Перевірка Docker daemon"
docker info 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) { Write-Err "Docker daemon недоступний." }
Write-OK "Docker daemon працює."

Write-Step "4. Перевірка Docker Compose"
$cv = docker compose version 2>&1; if ($LASTEXITCODE -eq 0) { Write-OK "Compose: $cv" }
else { Write-Err "Docker Compose не знайдено." }

Write-Step "5. mkcert"
$mkcert = Get-Command "mkcert" -ErrorAction SilentlyContinue
if ($mkcert) {
    Write-OK "mkcert знайдено."
    $caRoot = & mkcert -CAROOT 2>&1
    Write-OK "CA каталог: $caRoot"
} else {
    Write-Warn "mkcert не знайдено."
    $response = Read-Host "Встановити mkcert через winget? (Y/N)"
    if ($response -eq "Y" -or $response -eq "y") {
        Write-Host "Встановлення mkcert..." -ForegroundColor Yellow
        winget install FiloSottile.mkcert
        if ($LASTEXITCODE -ne 0) { Write-Err "Не вдалося встановити mkcert через winget." }
        Write-OK "mkcert встановлено."
        $mkcert = Get-Command "mkcert" -ErrorAction SilentlyContinue
    } else {
        Write-Warn "Пропущено. Встановіть вручну: winget install FiloSottile.mkcert"
    }
}

Write-Step "6. Локальний CA"
if ($mkcert) {
    $response = Read-Host "Створити та встановити локальний CA (mkcert -install)? (Y/N)"
    if ($response -eq "Y" -or $response -eq "y") {
        & $mkcert.Path -install
        if ($LASTEXITCODE -eq 0) { Write-OK "CA створено та встановлено." }
        else { Write-Err "Не вдалося створити CA." }
    } else {
        Write-Warn "Пропущено. За потреби: mkcert -install"
    }
}

Write-Step "7. PowerShell Execution Policy"
$policy = Get-ExecutionPolicy -Scope CurrentUser
if ($policy -eq "Restricted") {
    Write-Warn "Поточна політика: Restricted."
    $response = Read-Host "Змінити на RemoteSigned? (Y/N)"
    if ($response -eq "Y" -or $response -eq "y") {
        Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
        Write-OK "Політику змінено на RemoteSigned."
    }
} else {
    Write-OK "Політика: $policy"
}

Write-Step "8. Файл hosts"
Write-Host "Переконайтеся, що у файлі hosts є записи:" -ForegroundColor Yellow
Write-Host "  127.0.0.1 traefik.home.arpa" -ForegroundColor Yellow
Write-Host "  127.0.0.1 demo.home.arpa" -ForegroundColor Yellow

Write-Step "Підсумок"
Write-OK "Підготовку завершено."
Write-Host ""
Write-Host "Далі:" -ForegroundColor Cyan
Write-Host "  .\scripts\setup.ps1" -ForegroundColor Cyan
Write-Host "  docker compose up -d" -ForegroundColor Cyan
