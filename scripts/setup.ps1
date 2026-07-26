<#
.SYNOPSIS
    Налаштовує та перевіряє середовище docker-local-hosting.
.DESCRIPTION
    Скрипт виконує повну перевірку готовності системи: Git, Docker, .env,
    сертифікати, мережу. За потреби автоматично створює сертифікати та мережу.
.EXAMPLE
    .\scripts\setup.ps1
#>

$ErrorActionPreference = "Stop"
$rootDir = Resolve-Path -Path "$PSScriptRoot\.."

function Write-Step { param([string]$m) Write-Host "`n==> $m" -ForegroundColor Cyan }
function Write-OK   { param([string]$m) Write-Host "[OK] $m" -ForegroundColor Green }
function Write-Warn { param([string]$m) Write-Host "[УВАГА] $m" -ForegroundColor Yellow }
function Write-Err  { param([string]$m) Write-Host "[ПОМИЛКА] $m" -ForegroundColor Red; exit 1 }

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Docker Local Hosting — налаштування" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# 1. Git
Write-Step "1. Перевірка Git"
if (git --version 2>&1) { Write-OK "Git знайдено." }
else { Write-Warn "Git не знайдено." }

# 2. Docker
Write-Step "2. Перевірка Docker"
$dv = docker --version 2>&1; if ($LASTEXITCODE -eq 0) { Write-OK "Docker: $dv" }
else { Write-Err "Docker не знайдено. Встановіть Docker Desktop." }

# 3. Docker daemon
Write-Step "3. Перевірка Docker daemon"
docker info 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) { Write-Err "Docker daemon недоступний. Запустіть Docker Desktop." }
Write-OK "Docker daemon працює."

# 4. Docker Compose
Write-Step "4. Перевірка Docker Compose"
$cv = docker compose version 2>&1; if ($LASTEXITCODE -eq 0) { Write-OK "Compose: $cv" }
else { Write-Err "Docker Compose не знайдено." }

# 5. .env
Write-Step "5. Перевірка .env"
$envFile = Join-Path $rootDir ".env"
$envExample = Join-Path $rootDir ".env.example"
if (Test-Path $envFile) {
    Write-OK "Файл .env існує."
    $envContent = Get-Content $envFile -Raw
    if ($envContent -match 'TRAEFIK_BASIC_AUTH=$') {
        Write-Warn "TRAEFIK_BASIC_AUTH порожній. Dashboard буде недоступний."
    }
} else {
    Write-Warn "Файл .env відсутній. Створюю з .env.example..."
    if (Test-Path $envExample) {
        Copy-Item $envExample $envFile
        Write-OK "Створено .env з .env.example."
        Write-Warn "Відредагуйте .env, особливо TRAEFIK_BASIC_AUTH."
    } else { Write-Err ".env.example відсутній." }
}

# Завантаження змінних
if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        if ($_ -match '^([^#=]+)=(.+)$') { Set-Item -Path "env:$($matches[1])" -Value $matches[2] 2>$null }
    }
}
$networkName = $env:LOCAL_HOSTING_NETWORK
if (-not $networkName) { $networkName = "local-hosting" }
$certFile = $env:TLS_CERT_FILE
if (-not $certFile) { $certFile = "./certs/home.arpa.pem" }
$certFile = $certFile.Replace("./", "$rootDir\")
$keyFile = $env:TLS_KEY_FILE
if (-not $keyFile) { $keyFile = "./certs/home.arpa-key.pem" }
$keyFile = $keyFile.Replace("./", "$rootDir\")
$autoCerts = $env:AUTO_GENERATE_CERTS
if (-not $autoCerts) { $autoCerts = "true" }
$autoNetwork = $env:AUTO_CREATE_NETWORK
if (-not $autoNetwork) { $autoNetwork = "true" }

# 6. Мережа
Write-Step "6. Перевірка мережі $networkName"
$netExists = docker network ls --format "{{.Name}}" 2>&1 | Select-String -Pattern "^$([regex]::Escape($networkName))$"
if ($netExists) {
    Write-OK "Мережа $networkName існує."
} elseif ($autoNetwork -eq "true") {
    Write-Warn "Мережа $networkName відсутня. Створюю..."
    docker network create $networkName --driver bridge --attachable
    if ($LASTEXITCODE -eq 0) { Write-OK "Мережу $networkName створено." }
    else { Write-Err "Не вдалося створити мережу $networkName." }
} else {
    Write-Warn "Мережа $networkName відсутня. Створіть вручну:"
    Write-Host "  docker network create $networkName --driver bridge --attachable" -ForegroundColor Yellow
}

# 7. Сертифікати
Write-Step "7. Перевірка сертифікатів"
$certExists = Test-Path $certFile
$keyExists = Test-Path $keyFile

if ($certExists -and $keyExists) {
    Write-OK "Сертифікати знайдено."
    $certSize = (Get-Item $certFile).Length
    $keySize = (Get-Item $keyFile).Length
    if ($certSize -eq 0) { Write-Err "Файл сертифіката порожній." }
    if ($keySize -eq 0) { Write-Err "Файл ключа порожній." }
    if ($certSize -gt 0 -and $keySize -gt 0) {
        try {
            $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 $certFile
            $notAfter = $cert.NotAfter
            $daysLeft = ($notAfter - (Get-Date)).Days
            if ($daysLeft -lt 0) { Write-Warn "Сертифікат прострочено ($daysLeft днів)." }
            elseif ($daysLeft -lt 30) { Write-Warn "Сертифікат скоро прострочиться (${daysLeft} днів)." }
            else { Write-OK "Сертифікат дійсний ще $daysLeft днів." }
            $cert.Dispose()
        } catch {
            Write-Warn "Не вдалося перевірити строк дії сертифіката."
        }
    }
} else {
    if ($autoCerts -eq "true") {
        Write-Warn "Сертифікати не знайдено. Запускаю генерацію..."
        $genScript = Join-Path $PSScriptRoot "generate-certs.ps1"
        & $genScript
        if ($LASTEXITCODE -ne 0) { Write-Err "Генерація сертифікатів не вдалася." }
        Write-OK "Сертифікати згенеровано."
    } else {
        Write-Warn "Сертифікати не знайдено. Згенеруйте вручну:"
        Write-Host "  .\scripts\generate-certs.ps1" -ForegroundColor Yellow
    }
}

# 8. Перевірка gitignore
Write-Step "8. Перевірка .gitignore"
$gitignore = Join-Path $rootDir ".gitignore"
if (Test-Path $gitignore) {
    $content = Get-Content $gitignore -Raw
    if ($content -match '(?m)^certs/\*\.pem$') { Write-OK "Сертифікати виключені з Git." }
    else { Write-Warn "certs/*.pem не знайдено в .gitignore." }
    if ($content -match '(?m)^\.env$') { Write-OK ".env виключений з Git." }
    else { Write-Warn ".env не знайдено в .gitignore." }
}

# 9. Валідація Compose
Write-Step "9. Валідація Docker Compose"
docker compose config 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) { Write-OK "Конфігурація Docker Compose валідна." }
else {
    $err = docker compose config 2>&1
    Write-Err "Помилка: $err"
}

# Підсумок
Write-Step "Підсумок"
Write-OK "Налаштування завершено."
Write-Host ""
Write-Host "Запустіть проєкт:" -ForegroundColor Cyan
Write-Host "  docker compose up -d" -ForegroundColor Cyan
Write-Host ""
Write-Host "Перед запуском:" -ForegroundColor Yellow
Write-Host "  1. Додайте записи у файл hosts (адміністратор)" -ForegroundColor Yellow
Write-Host "     C:\Windows\System32\drivers\etc\hosts" -ForegroundColor Yellow
Write-Host "  2. Переконайтеся, що mkcert CA встановлено: mkcert -install" -ForegroundColor Yellow
Write-Host "  3. Відкрийте https://demo.home.arpa" -ForegroundColor Yellow
exit 0
