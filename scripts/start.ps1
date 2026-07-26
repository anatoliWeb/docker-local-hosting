<#
.SYNOPSIS
    Рекомендований запуск docker-local-hosting.
.DESCRIPTION
    Перевіряє оточення, .env, сертифікати, запускає docker compose up -d.
    Для першого запуску спочатку виконайте .\scripts\install-prerequisites.ps1.
.EXAMPLE
    .\scripts\start.ps1
#>

$ErrorActionPreference = "Stop"
$rootDir = Resolve-Path -Path "$PSScriptRoot\.."

function Write-Step { param([string]$m) Write-Host "`n==> $m" -ForegroundColor Cyan }
function Write-OK   { param([string]$m) Write-Host "[OK] $m" -ForegroundColor Green }
function Write-Warn { param([string]$m) Write-Host "[УВАГА] $m" -ForegroundColor Yellow }
function Write-Err  { param([string]$m) Write-Host "[ПОМИЛКА] $m" -ForegroundColor Red; exit 1 }

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  Docker Local Hosting — запуск" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

# 1. Docker
Write-Step "1. Docker"
docker info 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) { Write-Err "Docker daemon недоступний." }
Write-OK "Docker daemon працює."

# 2. .env
Write-Step "2. .env"
$envFile = Join-Path $rootDir ".env"
$envExample = Join-Path $rootDir ".env.example"
if (-not (Test-Path $envFile)) {
    if (Test-Path $envExample) {
        Copy-Item $envExample $envFile
        Write-OK "Створено .env iз .env.example."
        Write-Warn "Відредагуйте .env за потреби."
    } else { Write-Err ".env.example відсутній." }
} else {
    Write-OK ".env iснує."
}

Get-Content $envFile | ForEach-Object {
    if ($_ -match '^([^#=]+)=(.+)$') { Set-Item -Path "env:$($matches[1])" -Value $matches[2] 2>$null }
}

# 3. Basic Auth
Write-Step "3. Basic Auth"
$usersFile = Join-Path $rootDir "secrets\traefik-users"
if (Test-Path $usersFile) {
    $usersSize = (Get-Item $usersFile).Length
    if ($usersSize -gt 0) {
        Write-OK "Dashboard захищений Basic Auth: secrets/traefik-users."
    } else { Write-Warn "secrets/traefik-users порожній. Запустіть: .\scripts\generate-dashboard-auth.ps1" }
} else {
    Write-Warn "secrets/traefik-users відсутній. Dashboard буде недоступний (401)."
    Write-Host "  Створіть: .\scripts\generate-dashboard-auth.ps1" -ForegroundColor Yellow
}

# 4. mkcert
Write-Step "4. mkcert"
$mkcert = Get-Command "mkcert" -ErrorAction SilentlyContinue
if ($mkcert) {
    Write-OK "mkcert знайдено: $($mkcert.Path)"
} else {
    Write-Warn "mkcert не знайдено. Сертифікати не будуть згенеровані."
    Write-Host "  Встановіть: winget install FiloSottile.mkcert" -ForegroundColor Yellow
}

# 5. TLS сертифікати
Write-Step "5. TLS сертифікати"
$certRel = $env:TLS_CERT_FILE
if (-not $certRel) { $certRel = "./certs/home.arpa.pem" }
$keyRel = $env:TLS_KEY_FILE
if (-not $keyRel) { $keyRel = "./certs/home.arpa-key.pem" }
$certFile = [System.IO.Path]::GetFullPath((Join-Path $rootDir $certRel.Replace("./", "")))
$keyFile = [System.IO.Path]::GetFullPath((Join-Path $rootDir $keyRel.Replace("./", "")))

$certExists = Test-Path $certFile
$keyExists = Test-Path $keyFile

if ($certExists -and $keyExists) {
    $certSize = (Get-Item $certFile).Length
    $keySize = (Get-Item $keyFile).Length
    if ($certSize -gt 0 -and $keySize -gt 0) {
        Write-OK "Сертифікати знайдено."
    } else {
        Write-Warn "Сертифікати пошкоджено."
        $certExists = $false
    }
} else {
    Write-Warn "Сертифікати не знайдено."
}

if (-not $certExists -or -not $keyExists) {
    if ($mkcert) {
        $response = Read-Host "Згенерувати сертифікати? (Y/N)"
        if ($response -eq "Y" -or $response -eq "y") {
            $genScript = Join-Path $PSScriptRoot "generate-certs.ps1"
            & $genScript
            if ($LASTEXITCODE -ne 0) { Write-Err "Генерація сертифікатів не вдалася." }
            Write-OK "Сертифікати згенеровано."
        } else {
            Write-Warn "Пропущено. Згенеруйте: .\scripts\generate-certs.ps1"
        }
    } else {
        Write-Warn "Згенеруйте сертифікати вручну: .\scripts\generate-certs.ps1"
        Write-Host "  Або: mkcert -cert-file certs/home.arpa.pem -key-file certs/home.arpa-key.pem home.arpa *.home.arpa" -ForegroundColor Yellow
    }
}

# 6. Docker Compose config
Write-Step "6. Валідація Docker Compose"
docker compose config 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    $err = docker compose config 2>&1
    Write-Err "Помилка: $err"
}
Write-OK "Конфігурація валідна."

# 7. Запуск
Write-Step "7. Запуск"
docker compose up -d
if ($LASTEXITCODE -ne 0) { Write-Err "Не вдалося запустити." }
Write-OK "docker compose up -d виконано."

# 8. Очікування healthcheck
Write-Step "8. Очікування готовності"
Write-Host "Очікування готовності Traefik..." -ForegroundColor Yellow
Start-Sleep -Seconds 3
$retries = 12
for ($i = 0; $i -lt $retries; $i++) {
    $health = docker inspect --format "{{.State.Health.Status}}" traefik 2>$null
    if ($health -eq "healthy") { break }
    Start-Sleep -Seconds 5
}
$health = docker inspect --format "{{.State.Health.Status}}" traefik 2>$null
if ($health -eq "healthy") { Write-OK "Traefik готовий." }
else { Write-Warn "Traefik: $health" }

# 9. Підсумок
Write-Step "9. Підсумок"
Write-Host ""
Write-Host "Сайти доступні:" -ForegroundColor Cyan
Write-Host "  https://demo.home.arpa" -ForegroundColor Green
Write-Host "  https://traefik.home.arpa (Dashboard)" -ForegroundColor Green
Write-Host ""
Write-Host "Команди:" -ForegroundColor Cyan
Write-Host "  .\scripts\status.ps1    — статус" -ForegroundColor Cyan
Write-Host "  .\scripts\logs.ps1      — логи" -ForegroundColor Cyan
Write-Host "  .\scripts\stop.ps1      — зупинка" -ForegroundColor Cyan
Write-Host "  .\scripts\update.ps1    — оновлення" -ForegroundColor Cyan
Write-OK "Запуск завершено."
