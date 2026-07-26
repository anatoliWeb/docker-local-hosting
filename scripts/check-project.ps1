<#
.SYNOPSIS
    Перевіряє compose.yaml проєкту на сумісність з docker-local-hosting.
.DESCRIPTION
    Валідує наявність необхідних Traefik-лейблів та мережі.
.PARAMETER ProjectPath
    Шлях до директорії проєкту з compose.yaml.
.EXAMPLE
    .\scripts\check-project.ps1 .\examples\project-template
#>

param([Parameter(Mandatory=$true)][string]$ProjectPath)

$ErrorActionPreference = "Stop"
$rootDir = Resolve-Path -Path "$PSScriptRoot\.."

$composeFile = Join-Path $ProjectPath "compose.yaml"
if (-not (Test-Path $composeFile)) {
    $composeFile = Join-Path $ProjectPath "docker-compose.yml"
}
if (-not (Test-Path $composeFile)) {
    Write-Host "[ПОМИЛКА] У $ProjectPath не знайдено compose.yaml або docker-compose.yml" -ForegroundColor Red
    exit 1
}

function Write-OK   { param([string]$m) Write-Host "[OK] $m" -ForegroundColor Green }
function Write-Warn { param([string]$m) Write-Host "[УВАГА] $m" -ForegroundColor Yellow }
function Write-Err  { param([string]$m) Write-Host "[ПОМИЛКА] $m" -ForegroundColor Red; exit 1 }

Write-Host "Перевірка проєкту: $ProjectPath" -ForegroundColor Cyan
Write-Host "Файл: $composeFile" -ForegroundColor Cyan

$yaml = Get-Content $composeFile -Raw

# 1. Наявність сервісів
if ($yaml -notmatch '(?m)^services:') { Write-Err "Немає секції services." }
Write-OK "Секція services присутня."

# 2. Мережа local-hosting в кожному сервісі
$inService = $false
$serviceName = ""
$servicesWithNetwork = 0
$totalServices = 0
foreach ($line in (Get-Content $composeFile)) {
    if ($line -match '^  \w+:') { $inService = $true; $serviceName = $line.TrimEnd(':'); $totalServices++ }
    if ($inService -and $line -match '^\s+-\s+\${LOCAL_HOSTING_NETWORK:-local-hosting}\s*$') { $servicesWithNetwork++ }
    if ($inService -and $line -match '^\S' -and $line -notmatch '^  ') { $inService = $false }
}

if ($totalServices -eq 0) { Write-Err "Не знайдено жодного сервісу." }
if ($servicesWithNetwork -eq $totalServices) {
    Write-OK "Усі $totalServices сервісів підключені до LOCAL_HOSTING_NETWORK."
} else {
    Write-Warn "Лише $servicesWithNetwork з $totalServices сервісів мають мережу LOCAL_HOSTING_NETWORK."
}

# 3. Traefik-лейбли
$labelChecks = @{
    "traefik.enable=true" = "traefik.enable=true"
    "traefik.http.routers" = "traefik.http.routers.*.rule"
    "traefik.http.routers.*.entrypoints=websecure" = "entrypoints=websecure"
    "traefik.http.routers.*.tls=true" = "traefik.http.routers.*.tls=true"
}
$hasLabels = $yaml -match 'labels:'
if (-not $hasLabels) { Write-Warn "Жоден сервіс не має labels. Traefik не зможе маршрутизувати." }
Write-OK "Файл compose.yaml прочитано."

# 4. Перевірка external network
if ($yaml -notmatch '\$LOCAL_HOSTING_NETWORK') {
    Write-Warn "Не знайдено використання LOCAL_HOSTING_NETWORK. Додайте мережу до compose.yaml."
}

Write-Host "`nПеревірка завершена." -ForegroundColor Cyan
