<#
.SYNOPSIS
    Перевіряє compose.yaml проєкту на сумісність з docker-local-hosting.
    Валідує наявність необхідних Traefik-лейблів, мережі, та порту.
.PARAMETER ProjectPath
    Шлях до директорії проєкту з compose.yaml.
.EXAMPLE
    .\scripts\check-project.ps1 .\examples\project-template
#>

param([Parameter(Mandatory=$true)][string]$ProjectPath)

$ErrorActionPreference = "Stop"
$rootDir = Resolve-Path -Path "$PSScriptRoot\.."

$composeFile = Join-Path $ProjectPath "compose.yaml"
if (-not (Test-Path $composeFile)) { $composeFile = Join-Path $ProjectPath "docker-compose.yml" }
if (-not (Test-Path $composeFile)) { Write-Host "[ПОМИЛКА] У $ProjectPath не знайдено compose-файл" -ForegroundColor Red; exit 1 }

function Write-OK   { param([string]$m) Write-Host "[OK] $m" -ForegroundColor Green }
function Write-Warn { param([string]$m) Write-Host "[УВАГА] $m" -ForegroundColor Yellow }
function Write-Err  { param([string]$m) Write-Host "[ПОМИЛКА] $m" -ForegroundColor Red; exit 1 }

Write-Host "Перевірка проєкту: $ProjectPath" -ForegroundColor Cyan
Write-Host "Файл: $composeFile" -ForegroundColor Cyan

$yaml = Get-Content $composeFile -Raw
$lines = Get-Content $composeFile

if ($yaml -notmatch '(?m)^services:') { Write-Err "Немає секції services." }
Write-OK "Секція services присутня."

# Мережа
$inService = $false; $servicesWithNetwork = 0; $totalServices = 0
foreach ($line in $lines) {
    if ($line -match '^  \w+:') { $inService = $true; $totalServices++ }
    if ($inService -and $line -match '^\s+-\s+\$\{?LOCAL_HOSTING_NETWORK') { $servicesWithNetwork++ }
    if ($inService -and $line -match '^\S' -and $line -notmatch '^  ') { $inService = $false }
}
if ($servicesWithNetwork -eq $totalServices) {
    Write-OK "Усі $totalServices сервісів підключені до LOCAL_HOSTING_NETWORK."
} else { Write-Warn "Лише $servicesWithNetwork з $totalServices мають мережу." }

# Traefik-лейбли
if ($yaml -match 'traefik.enable=true') { Write-OK "traefik.enable=true знайдено." }
else { Write-Warn "Не знайдено traefik.enable=true." }

if ($yaml -match 'traefik.http.routers') { Write-OK "traefik.http.routers знайдено." }
else { Write-Warn "Не знайдено traefik.http.routers." }

if ($yaml -match 'entrypoints=websecure') { Write-OK "entrypoints=websecure знайдено." }
else { Write-Warn "Не знайдено entrypoints=websecure." }

if ($yaml -match 'tls=true') { Write-OK "tls=true знайдено." }
else { Write-Warn "Не знайдено tls=true." }

# Аналіз порту
Write-Host "" -ForegroundColor Cyan
Write-Host "=== Аналіз порту ===" -ForegroundColor Cyan
$hasServerPort = $yaml -match 'loadbalancer\.server\.port'
$hasExpose = $yaml -match '(?m)^\s+expose:'
if ($hasServerPort) {
    Write-OK "Явний server.port знайдено."
} else {
    if ($hasExpose) {
        $exposeLines = $lines | Where-Object { $_ -match '^\s+-\s+"?\d+"?' }
        $exposeCount = ($exposeLines | Measure-Object).Count
        if ($exposeCount -eq 1) {
            $exposePort = ($exposeLines[0] -replace '^\s+-\s+"?(\d+)"?', '$1')
            Write-OK "АВТОВИЗНАЧЕННЯ БЕЗПЕЧНЕ: image expose один порт $exposePort."
        } else {
            Write-Warn "ПОТРIБНО ВКАЗАТИ APP_INTERNAL_PORT: image expose $exposeCount портiв."
        }
    } else {
        Write-Warn "Немає expose та server.port. Traefik може не знайти порт."
    }
}

Write-Host "" -ForegroundColor Cyan
Write-Host "=== External service ===" -ForegroundColor Cyan
if ($yaml -match 'external: true') { Write-OK "Мережа external: true." }
else { Write-Warn "Немає external: true. Переконайтеся що це стороннiй проєкт." }

Write-Host "`nПеревірка завершена." -ForegroundColor Cyan
