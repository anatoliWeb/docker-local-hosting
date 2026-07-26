<#
.SYNOPSIS
    Показує статус сервісів docker-local-hosting.
.EXAMPLE
    .\scripts\status.ps1
#>

$ErrorActionPreference = "Continue"
$rootDir = Resolve-Path -Path "$PSScriptRoot\.."

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  Docker Local Hosting — статус" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "=== Docker Compose ===" -ForegroundColor Cyan
Set-Location $rootDir
docker compose ps 2>&1

Write-Host ""
Write-Host "=== Мережі ===" -ForegroundColor Cyan
$netName = "local-hosting"
if (Test-Path .env) {
    $netMatch = Select-String -Path .env -Pattern '^LOCAL_HOSTING_NETWORK=(.+)$' | ForEach-Object { $_.Matches.Groups[1].Value }
    if ($netMatch) { $netName = $netMatch }
}
docker network ls --filter "name=$netName" --format "table {{.Name}}\t{{.Driver}}\t{{.Scope}}" 2>&1

Write-Host ""
Write-Host "=== Сертифікати ===" -ForegroundColor Cyan
$certFile = ".\certs\home.arpa.pem"
$keyFile = ".\certs\home.arpa-key.pem"
if (Test-Path $certFile) { Write-Host "Сертифікат: $((Get-Item $certFile).Length) байт" -ForegroundColor Green }
else { Write-Host "Сертифікат: НЕ ЗНАЙДЕНО" -ForegroundColor Red }
if (Test-Path $keyFile) { Write-Host "Ключ: $((Get-Item $keyFile).Length) байт" -ForegroundColor Green }
else { Write-Host "Ключ: НЕ ЗНАЙДЕНО" -ForegroundColor Red }

Write-Host ""
Write-Host "Докладніше: docker compose logs --tail=50" -ForegroundColor Yellow
