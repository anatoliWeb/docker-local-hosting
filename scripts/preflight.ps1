<#
.SYNOPSIS
    Перевіряє готовність системи без внесення змін.
.PARAMETER AllowMissingStartupPrerequisites
    Позначає відсутній Basic Auth або TLS як попередження для start.ps1.
#>

param([switch]$AllowMissingStartupPrerequisites)

$ErrorActionPreference = "Continue"
$errors = 0
$warnings = 0
$rootDir = Resolve-Path -Path "$PSScriptRoot\.."
Set-Location -LiteralPath $rootDir

function Pass([string]$Text) { Write-Host "  [ГОТОВО] $Text" -ForegroundColor Green }
function Warn([string]$Text) { Write-Host "  [ПОПЕРЕДЖЕННЯ] $Text" -ForegroundColor Yellow; $script:warnings++ }
function Fail([string]$Text) { Write-Host "  [ПОМИЛКА] $Text" -ForegroundColor Red; $script:errors++ }
function Step([string]$Text) { Write-Host "`n==> $Text" -ForegroundColor Cyan }
function Require-File([string]$Path, [string]$Name) {
    if ((Test-Path -LiteralPath $Path -PathType Leaf) -and ((Get-Item -LiteralPath $Path).Length -gt 0)) { Pass $Name; return $true }
    if ($AllowMissingStartupPrerequisites) { Warn "$Name відсутній" } else { Fail "$Name відсутній" }
    return $false
}

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  Preflight — перевірка готовності" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

Step "1. Файли середовища"
$envFile = Join-Path $rootDir ".env"
if (Test-Path -LiteralPath $envFile) { Pass ".env існує" }
else { Fail ".env відсутній. Запустіть .\start.ps1, щоб автоматично створити .env." }
if (Test-Path -LiteralPath (Join-Path $rootDir ".env.example")) { Pass ".env.example існує" } else { Fail ".env.example відсутній" }

Step "2. Docker і Compose"
if (Get-Command docker -ErrorAction SilentlyContinue) { Pass "Docker знайдено" } else { Fail "Docker не знайдено" }
docker info 2>$null | Out-Null
if ($LASTEXITCODE -eq 0) { Pass "Docker daemon працює" } else { Fail "Docker daemon недоступний" }
docker compose version 2>$null | Out-Null
if ($LASTEXITCODE -eq 0) { Pass "Docker Compose доступний" } else { Fail "Docker Compose недоступний" }

Step "3. Dashboard і TLS"
Require-File (Join-Path $rootDir "secrets\traefik-users") "secrets/traefik-users" | Out-Null
$mkcert = Get-Command mkcert -ErrorAction SilentlyContinue
if ($mkcert) {
    Pass "mkcert знайдено"
    $caRoot = & mkcert -CAROOT 2>$null
    if ($LASTEXITCODE -eq 0 -and (Test-Path (Join-Path $caRoot "rootCA.pem"))) { Pass "Локальний CA mkcert встановлено" }
    else { Fail "Локальний CA mkcert не підтверджено. Виконайте: mkcert -install" }
} else { Fail "mkcert не знайдено" }
Require-File (Join-Path $rootDir "certs\home.arpa.pem") "TLS сертифікат" | Out-Null
Require-File (Join-Path $rootDir "certs\home.arpa-key.pem") "TLS ключ" | Out-Null

Step "4. Compose і мережа"
$configOutput = docker compose config 2>&1
if ($LASTEXITCODE -eq 0) { Pass "Конфігурація Docker Compose валідна" }
else { Fail "Конфігурація Docker Compose невалідна"; $configOutput | ForEach-Object { Write-Host "    $_" } }
$network = "local-hosting"
if (Test-Path $envFile) {
    $networkLine = Get-Content $envFile | Where-Object { $_ -match '^LOCAL_HOSTING_NETWORK=(.+)$' } | Select-Object -First 1
    if ($networkLine) { $network = $networkLine.Split("=", 2)[1] }
}
docker network inspect $network 2>$null | Out-Null
if ($LASTEXITCODE -eq 0) { Pass "Мережа $network існує" } else { Warn "Мережа $network буде створена під час запуску" }
foreach ($port in 80, 443) {
    $listener = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue
    if ($listener) { Warn "Порт $port уже зайнятий" } else { Pass "Порт $port вільний" }
}

Step "5. Безпека і конфігурація"
foreach ($path in @(".env", "certs/home.arpa-key.pem", "secrets/traefik-users")) {
    git check-ignore -q -- $path 2>$null
    if ($LASTEXITCODE -eq 0) { Pass "$path ігнорується Git" } else { Fail "$path не ігнорується Git" }
}
$traefikStatic = Get-Content (Join-Path $rootDir "config\traefik\traefik.yaml") -Raw
$dashboard = Get-Content (Join-Path $rootDir "config\traefik\dynamic\dashboard.yaml") -Raw
$compose = Get-Content (Join-Path $rootDir "compose.yaml") -Raw
if ($traefikStatic -match 'exposedByDefault:\s*false') { Pass "exposedByDefault=false" } else { Fail "exposedByDefault=false відсутній" }
if ($traefikStatic -notmatch 'api\.insecure') { Pass "api.insecure не використовується" } else { Fail "api.insecure знайдено" }
if ($dashboard -match 'usersFile:\s*/run/secrets/traefik-users' -and $dashboard -notmatch '(?m)^\s*users:') { Pass "Dashboard використовує usersFile" } else { Fail "Dashboard Basic Auth налаштовано небезпечно" }
$traefikService = [regex]::Match($compose, '(?ms)^  traefik:\s*\n(.*?)(?=^  [a-zA-Z][a-zA-Z0-9-]*:|\z)').Value
if ($traefikService -and $traefikService -notmatch '/var/run/docker\.sock') { Pass "Traefik не має прямого Docker socket" } else { Fail "Traefik має прямий Docker socket" }
if ($compose -match '/var/run/docker\.sock:/var/run/docker\.sock:ro' -and $compose -notmatch 'docker-socket-proxy:\s*.*?ports:') { Pass "Socket Proxy має read-only socket без host port" } else { Fail "Socket Proxy налаштовано небезпечно" }
if ($compose -match './config/traefik/dynamic:/etc/traefik/dynamic') { Pass "Dynamic directory змонтовано для File Provider" } else { Fail "Dynamic directory не змонтовано" }

Step "6. Версії образів"
$versionHits = git ls-files "*.yaml" "*.yml" | ForEach-Object { Select-String -Path $_ -Pattern ':latest|stable-alpine' }
if ($versionHits) { Fail "Знайдено неприкріплені версії образів"; $versionHits | ForEach-Object { Write-Host "    $($_.Path):$($_.LineNumber)" } }
else { Pass "У tracked YAML немає :latest або stable-alpine" }

Step "Підсумок"
if ($errors -eq 0) {
    Write-Host "  Система готова до ручного тестування" -ForegroundColor Green
} else {
    Write-Host "  Система НЕ готова до ручного тестування ($errors помилок, $warnings попереджень)" -ForegroundColor Red
}
exit $errors
