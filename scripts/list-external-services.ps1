<#
.SYNOPSIS
    Показує список зовнішніх сервісів, зареєстрованих у Traefik.
.DESCRIPTION
    Читає external-services.yaml та виводить ім'я, домен і бекенд кожного.
.EXAMPLE
    .\scripts\list-external-services.ps1
#>

$ErrorActionPreference = "Stop"
$rootDir = Resolve-Path -Path "$PSScriptRoot\.."
$registryFile = Join-Path $rootDir "config\traefik\dynamic\external-services.yaml"

if (-not (Test-Path $registryFile)) {
    Write-Host "Зовнішні сервіси не знайдено." -ForegroundColor Yellow
    exit 0
}

$content = Get-Content $registryFile -Raw -Encoding UTF8
$lines = $content -split "`n" | ForEach-Object { $_.TrimEnd("`r") }

$services = @{}
$currentName = $null
$inRouters = $false
$inServices = $false

foreach ($line in $lines) {
    if ($line -match '^  routers:\s*$') { $inRouters = $true; $inServices = $false; continue }
    if ($line -match '^  services:\s*$') { $inServices = $true; $inRouters = $false; continue }

    if ($inRouters -and $line -match '^    (\S+):$') {
        $currentName = $matches[1]
        if (-not $services.ContainsKey($currentName)) {
            $services[$currentName] = @{ Domain = ""; Url = "" }
        }
    }
    if ($inRouters -and $line -match 'rule:\s+"Host\(`(.+?)`\)"') {
        if ($currentName -and $services.ContainsKey($currentName)) {
            $services[$currentName].Domain = $matches[1]
        }
    }
    if ($inServices -and $line -match '^    (\S+):$') {
        $currentName = $matches[1]
        if (-not $services.ContainsKey($currentName)) {
            $services[$currentName] = @{ Domain = ""; Url = "" }
        }
    }
    if ($inServices -and $line -match 'url:\s+"(.+)"') {
        if ($currentName -and $services.ContainsKey($currentName)) {
            $services[$currentName].Url = $matches[1]
        }
    }
}

if ($services.Count -eq 0) {
    Write-Host "Зовнішні сервіси не знайдено." -ForegroundColor Yellow
    exit 0
}

Write-Host "Зовнішні сервіси Traefik:" -ForegroundColor Cyan
Write-Host ""

$services.Keys | Sort-Object | ForEach-Object {
    $svc = $services[$_]
    Write-Host "  $_" -ForegroundColor Green
    Write-Host "    Домен:   https://$($svc.Domain)" -ForegroundColor Gray
    Write-Host "    Бекенд:  $($svc.Url)" -ForegroundColor Gray
    Write-Host ""
}

Write-Host "Усього: $($services.Count)" -ForegroundColor Cyan
