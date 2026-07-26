<#
.SYNOPSIS
    Перевіряє готовність системи до ручного тестування.
.DESCRIPTION
    Нічого не змінює. Перевіряє всі критичні компоненти.
    Статуси: ГОТОВО, ПОПЕРЕДЖЕННЯ, ПОМИЛКА.
.EXAMPLE
    .\scripts\preflight.ps1
#>

$ErrorActionPreference = "Continue"
$global:errors = 0
$global:warnings = 0

function Write-Step   { param([string]$m) Write-Host "`n==> $m" -ForegroundColor Cyan }
function Write-Pass   { param([string]$m) Write-Host "  [ГОТОВО] $m" -ForegroundColor Green }
function Write-Warn   { param([string]$m) Write-Host "  [ПОПЕРЕДЖЕННЯ] $m" -ForegroundColor Yellow; $global:warnings++ }
function Write-Fail   { param([string]$m) Write-Host "  [ПОМИЛКА] $m" -ForegroundColor Red; $global:errors++ }

$rootDir = Resolve-Path -Path "$PSScriptRoot\.."
Set-Location $rootDir

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  Preflight - перевірка готовності" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

Write-Step "1. Каталог проєкту"
if ((Get-Location).Path -eq $rootDir) { Write-Pass "Робочий каталог: $rootDir" }
else { Write-Fail "Неправильний каталог" }

Write-Step "2. Git"
$gitVersion = git --version 2>&1
if ($LASTEXITCODE -eq 0) { Write-Pass "Git: $gitVersion" }
else { Write-Warn "Git не знайдено" }

Write-Step "3. Docker"
$dockerVersion = docker --version 2>&1
if ($LASTEXITCODE -eq 0) { Write-Pass "Docker: $dockerVersion" }
else { Write-Fail "Docker не знайдено"; exit 1 }

Write-Step "4. Docker daemon"
docker info 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) { Write-Pass "Docker daemon працює" }
else { Write-Fail "Docker daemon недоступний" }

Write-Step "5. Docker Compose"
$composeVersion = docker compose version 2>&1
if ($LASTEXITCODE -eq 0) { Write-Pass "Compose: $composeVersion" }
else { Write-Fail "Compose не знайдено" }

Write-Step "6. Файл .env"
$envFile = Join-Path $rootDir ".env"
if (Test-Path $envFile) { Write-Pass ".env існує" }
else { Write-Warn ".env відсутній" }
$envExample = Join-Path $rootDir ".env.example"
if (Test-Path $envExample) { Write-Pass ".env.example існує" }
else { Write-Fail ".env.example відсутній" }

Write-Step "7. Dashboard Basic Auth"
$usersFile = Join-Path $rootDir "secrets\traefik-users"
if (Test-Path $usersFile) {
    $usersSize = (Get-Item $usersFile).Length
    if ($usersSize -gt 0) { Write-Pass "secrets/traefik-users існує" }
    else { Write-Warn "secrets/traefik-users порожній" }
} else { Write-Warn "secrets/traefik-users відсутній" }

Write-Step "8. TLS сертифікати"
if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        if ($_ -match '^([^#=]+)=(.+)$') { Set-Item -Path "env:$($matches[1])" -Value $matches[2] 2>$null }
    }
}
$certRel = $env:TLS_CERT_FILE; if (-not $certRel) { $certRel = "./certs/home.arpa.pem" }
$keyRel  = $env:TLS_KEY_FILE;  if (-not $keyRel)  { $keyRel = "./certs/home.arpa-key.pem" }
$certFile = [System.IO.Path]::GetFullPath((Join-Path $rootDir $certRel.Replace("./", "")))
$keyFile  = [System.IO.Path]::GetFullPath((Join-Path $rootDir $keyRel.Replace("./", "")))
$certExists = Test-Path $certFile
$keyExists  = Test-Path $keyFile
if ($certExists -and $keyExists) {
    $certSize = (Get-Item $certFile).Length
    $keySize  = (Get-Item $keyFile).Length
    if ($certSize -gt 0 -and $keySize -gt 0) {
        Write-Pass "Сертифікати знайдено"
        try {
            $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 $certFile
            $daysLeft = ($cert.NotAfter - (Get-Date)).Days
            if ($daysLeft -lt 0) { Write-Warn "Сертифікат прострочено" }
            elseif ($daysLeft -lt 30) { Write-Warn "Сертифікат скоро прострочиться ($daysLeft дн.)" }
            else { Write-Pass "Сертифікат дійсний ще $daysLeft дн." }
            $cert.Dispose()
        } catch { Write-Warn "Не вдалося перевірити сертифікат" }
    } else { Write-Fail "Сертифікати пошкоджено" }
} else { Write-Warn "Сертифікати не знайдено" }

Write-Step "9. mkcert"
$mkcert = Get-Command "mkcert" -ErrorAction SilentlyContinue
if ($mkcert) {
    Write-Pass "mkcert знайдено: $($mkcert.Path)"
    $caRoot = & mkcert -CAROOT 2>&1
    $caCert = Join-Path "$caRoot" "rootCA.pem"
    if (Test-Path $caCert) { Write-Pass "Локальний CA встановлено" }
    else { Write-Warn "Локальний CA не встановлено. Виконайте: mkcert -install" }
} else { Write-Warn "mkcert не знайдено" }

Write-Step "10. Мережа local-hosting"
$netName = "local-hosting"
$netExists = docker network ls --format "{{.Name}}" 2>&1 | Select-String -Pattern "^$netName$"
if ($netExists) { Write-Pass "Мережа $netName існує" }
else { Write-Warn "Мережа $netName буде створена compose" }

Write-Step "11. Порти 80/443"
$port80 = netstat -an 2>$null | Select-String ":80 " | Select-String "LISTENING"
$port443 = netstat -an 2>$null | Select-String ":443 " | Select-String "LISTENING"
if ($port80) { Write-Warn "Порт 80 зайнятий" } else { Write-Pass "Порт 80 вільний" }
if ($port443) { Write-Warn "Порт 443 зайнятий" } else { Write-Pass "Порт 443 вільний" }

Write-Step "12. Docker Compose config"
$configOutput = docker compose config 2>&1
if ($LASTEXITCODE -eq 0) { Write-Pass "Конфігурація валідна" }
else { Write-Fail "Помилка: $configOutput" }

Write-Step "13. .gitignore"
$gitignore = Join-Path $rootDir ".gitignore"
if (Test-Path $gitignore) {
    $content = Get-Content $gitignore -Raw
    @(
        @{ Pattern = '(?m)^\.env$'; Name = '.env' },
        @{ Pattern = '(?m)^secrets/\*$'; Name = 'secrets/*' },
        @{ Pattern = '(?m)^certs/\*\.pem$'; Name = 'certs/*.pem' }
    ) | ForEach-Object {
        if ($content -match $_.Pattern) { Write-Pass "$($_.Name) виключено" }
        else { Write-Fail "$($_.Name) НЕ виключено" }
    }
} else { Write-Fail ".gitignore відсутній" }

Write-Step "14. Версії образів"
$latestFound = Get-ChildItem -Recurse -File -Include "*.yaml", "*.yml" | Select-String -Pattern ':latest' | Select-Object -First 5
$stableFound = Get-ChildItem -Recurse -File -Include "*.yaml", "*.yml" | Select-String -Pattern 'stable-alpine' | Select-Object -First 5
if ($latestFound) { Write-Fail "Знайдено :latest образи"; $latestFound | ForEach-Object { Write-Host "         $($_.Path):$($_.LineNumber)" } }
else { Write-Pass "Немає :latest образів" }
if ($stableFound) { Write-Fail "Знайдено stable-alpine образи" }
else { Write-Pass "Немає stable-alpine образів" }

Write-Step "15. api.insecure"
if (Select-String -Path "config/traefik/traefik.yaml" -Pattern 'api.insecure' -SimpleMatch -Quiet) {
    Write-Fail "api.insecure знайдено в traefik.yaml"
} else { Write-Pass "api.insecure не використовується" }

Write-Step "16. Docker socket"
$composeContent = Get-Content "compose.yaml" -Raw
if ($composeContent -match 'traefik.*/var/run/docker\.sock') {
    Write-Fail "Traefik має прямий доступ до Docker socket"
} else { Write-Pass "Traefik без прямого socket" }

Write-Step "17. Dashboard конфігурація"
$dashboardPath = Join-Path $rootDir "config/traefik/dynamic/dashboard.yaml"
if (Test-Path $dashboardPath) {
    $dashboardContent = Get-Content $dashboardPath -Raw
    if ($dashboardContent -match 'usersFile:') { Write-Pass "Використовується usersFile" }
    elseif ($dashboardContent -match 'users:') { Write-Warn "Можливий hardcoded hash" }
    else { Write-Warn "dashboard.yaml не містить Basic Auth" }
} else { Write-Fail "dashboard.yaml відсутній" }

Write-Step "Підсумок"
Write-Host ""
if ($global:errors -eq 0 -and $global:warnings -eq 0) {
    Write-Host "  Система готова до ручного тестування" -ForegroundColor Green
} elseif ($global:errors -eq 0) {
    Write-Host "  Система готова до ручного тестування ($global:warnings попереджень)" -ForegroundColor Yellow
} else {
    Write-Host "  Система НЕ готова до ручного тестування ($global:errors помилок, $global:warnings попереджень)" -ForegroundColor Red
}
exit $global:errors
