<#
.SYNOPSIS
    Оновлює образи docker-local-hosting до зафіксованих версій.
.DESCRIPTION
    Pull актуальні образи, recreate сервіси, не чіпає сторонні проєкти.
.EXAMPLE
    .\scripts\update.ps1
#>

$ErrorActionPreference = "Stop"
$rootDir = Resolve-Path -Path "$PSScriptRoot\.."

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  Docker Local Hosting — оновлення" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

Set-Location $rootDir

Write-Step "Pull нових образів..."
docker compose pull

Write-Host ""
Write-Host "Зміни:" -ForegroundColor Cyan
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.Size}}"

Write-Host ""
$response = Read-Host "Перезапустити сервіси з новими образами? (Y/N)"
if ($response -eq "Y" -or $response -eq "y") {
    docker compose up -d --force-recreate
    if ($LASTEXITCODE -eq 0) { Write-Host "[OK] Сервіси оновлено." -ForegroundColor Green }
    else { Write-Host "[ПОМИЛКА] Оновлення не вдалося." -ForegroundColor Red; exit 1 }
} else {
    Write-Host "Пропущено. За потреби: docker compose up -d --force-recreate" -ForegroundColor Yellow
}

