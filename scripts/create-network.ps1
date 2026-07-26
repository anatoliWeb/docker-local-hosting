<#
.SYNOPSIS
    Створює зовнішню Docker-мережу для docker-local-hosting.
.DESCRIPTION
    Читає змінну LOCAL_HOSTING_NETWORK із .env. Якщо мережа вже існує — нічого не робить.
.EXAMPLE
    .\scripts\create-network.ps1
#>

$ErrorActionPreference = "Stop"
$rootDir = Resolve-Path -Path "$PSScriptRoot\.."
$envFile = Join-Path $rootDir ".env"

if (-not (Test-Path $envFile)) {
    Write-Host "[ПОМИЛКА] .env не знайдено. Скопіюйте .env.example у .env." -ForegroundColor Red
    exit 1
}

Get-Content $envFile | ForEach-Object {
    if ($_ -match '^([^#=]+)=(.+)$') { Set-Item -Path "env:$($matches[1])" -Value $matches[2] 2>$null }
}

$networkName = $env:LOCAL_HOSTING_NETWORK
if (-not $networkName) { $networkName = "local-hosting" }

$exists = docker network ls --format "{{.Name}}" 2>&1 | Select-String -Pattern "^$([regex]::Escape($networkName))$"
if ($exists) {
    Write-Host "[OK] Мережа '$networkName' вже існує." -ForegroundColor Green
    exit 0
}

Write-Host "Створюю мережу '$networkName'..." -ForegroundColor Yellow
docker network create $networkName --driver bridge --attachable
if ($LASTEXITCODE -eq 0) {
    Write-Host "[OK] Мережу '$networkName' створено." -ForegroundColor Green
} else {
    Write-Host "[ПОМИЛКА] Не вдалося створити мережу '$networkName'." -ForegroundColor Red
    exit 1
}
