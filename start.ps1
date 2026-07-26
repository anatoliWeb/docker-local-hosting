<#
.SYNOPSIS
    Головна Windows-команда запуску docker-local-hosting.
#>

$ErrorActionPreference = "Stop"
$rootDir = Resolve-Path -Path $PSScriptRoot
Set-Location -LiteralPath $rootDir

function Stop-Start([string]$Message) {
    Write-Host "[ПОМИЛКА] $Message" -ForegroundColor Red
    exit 1
}

function Test-NonEmptyFile([string]$Path) {
    return (Test-Path -LiteralPath $Path -PathType Leaf) -and ((Get-Item -LiteralPath $Path).Length -gt 0)
}

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  Docker Local Hosting — запуск" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

& (Join-Path $rootDir "scripts\ensure-env.ps1")
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Stop-Start "Docker не знайдено. Встановіть Docker Desktop."
}

docker info --format "Docker daemon: {{.ServerVersion}}"
if ($LASTEXITCODE -ne 0) { Stop-Start "Docker daemon недоступний. Запустіть Docker Desktop." }

docker compose version
if ($LASTEXITCODE -ne 0) { Stop-Start "Docker Compose недоступний." }

Write-Host "`n==> Попередня перевірка" -ForegroundColor Cyan
& (Join-Path $rootDir "scripts\preflight.ps1") -AllowMissingStartupPrerequisites

$usersFile = Join-Path $rootDir "secrets\traefik-users"
if (-not (Test-NonEmptyFile $usersFile)) {
    Write-Host "`n[ПОМИЛКА] Не налаштовано Basic Auth для Dashboard." -ForegroundColor Red
    Write-Host "  Запустіть: .\scripts\generate-dashboard-auth.ps1" -ForegroundColor Yellow
    $answer = Read-Host "Запустити генератор зараз? (Y/N)"
    if ($answer -eq "Y" -or $answer -eq "y") {
        & (Join-Path $rootDir "scripts\generate-dashboard-auth.ps1")
    }
    if (-not (Test-NonEmptyFile $usersFile)) {
        Stop-Start "Без secrets/traefik-users запуск заблоковано."
    }
}

$certFile = Join-Path $rootDir "certs\home.arpa.pem"
$keyFile = Join-Path $rootDir "certs\home.arpa-key.pem"
if (-not (Test-NonEmptyFile $certFile) -or -not (Test-NonEmptyFile $keyFile)) {
    Write-Host "`n[ПОМИЛКА] TLS-сертифікат або ключ відсутній." -ForegroundColor Red
    Write-Host "  winget install FiloSottile.mkcert" -ForegroundColor Yellow
    Write-Host "  mkcert -install" -ForegroundColor Yellow
    Write-Host "  .\scripts\generate-certs.ps1" -ForegroundColor Yellow
    if (Get-Command mkcert -ErrorAction SilentlyContinue) {
        $answer = Read-Host "Згенерувати сертифікати через mkcert зараз? (Y/N)"
        if ($answer -eq "Y" -or $answer -eq "y") {
            & (Join-Path $rootDir "scripts\generate-certs.ps1")
        }
    }
    if (-not (Test-NonEmptyFile $certFile) -or -not (Test-NonEmptyFile $keyFile)) {
        Stop-Start "Без TLS-сертифікатів запуск заблоковано."
    }
}

Write-Host "`n==> Валідація Docker Compose" -ForegroundColor Cyan
$configOutput = docker compose config 2>&1
if ($LASTEXITCODE -ne 0) {
    $configOutput | ForEach-Object { Write-Host $_ -ForegroundColor Red }
    Stop-Start "Конфігурація Docker Compose невалідна."
}
Write-Host "[OK] Конфігурація Docker Compose валідна." -ForegroundColor Green

Write-Host "`n==> Запуск сервісів" -ForegroundColor Cyan
docker compose up -d
if ($LASTEXITCODE -ne 0) { Stop-Start "Не вдалося запустити сервіси." }

$deadline = (Get-Date).AddSeconds(90)
while ((Get-Date) -lt $deadline) {
    $bootstrap = docker inspect -f "{{.State.Status}}:{{.State.ExitCode}}" docker-local-hosting-bootstrap 2>$null
    $traefik = docker inspect -f "{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}" traefik 2>$null
    $demo = docker inspect -f "{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}" docker-local-hosting-demo 2>$null

    if ($bootstrap -eq "exited:0" -and $traefik -eq "healthy" -and $demo -eq "healthy") { break }
    if ($bootstrap -match "exited:[1-9]") { Stop-Start "Bootstrap завершився з помилкою. Перевірте: docker compose logs bootstrap" }
    Start-Sleep -Seconds 3
}

if ($bootstrap -ne "exited:0" -or $traefik -ne "healthy" -or $demo -ne "healthy") {
    Stop-Start "Сервіси не пройшли healthcheck за 90 секунд. Перевірте: docker compose logs"
}

Write-Host "`n==> Статус" -ForegroundColor Cyan
docker compose ps
Write-Host "`nГотово до ручного тестування:" -ForegroundColor Green
Write-Host "  https://demo.home.arpa" -ForegroundColor Green
Write-Host "  https://traefik.home.arpa/dashboard/" -ForegroundColor Green
Write-Host "  docs/MANUAL-TESTING-WINDOWS.md" -ForegroundColor Green
