<#
.SYNOPSIS
    Виводить рядки для /etc/hosts або C:\Windows\System32\drivers\etc\hosts
.DESCRIPTION
    Читає домени з .env або аргументу командного рядка.
    Виводить готовий блок для додавання в hosts-файл.
.PARAMETER Domains
    Список доменів через пробіл (якщо не вказано - читає з .env).
.EXAMPLE
    .\scripts\show-hosts-entry.ps1
    .\scripts\show-hosts-entry.ps1 myapp.home.arpa
    .\scripts\show-hosts-entry.ps1 app1.home.arpa app2.home.arpa
#>

param([string[]]$Domains)

$rootDir = Resolve-Path -Path "$PSScriptRoot\.."
$envFile = Join-Path $rootDir ".env"

if ($Domains.Count -eq 0) {
    if (Test-Path $envFile) {
        Get-Content $envFile | ForEach-Object {
            if ($_ -match '^([^#=]+)=(.+)$') { Set-Item -Path "env:$($matches[1])" -Value $matches[2] 2>$null }
        }
        $knownDomains = @()
        if ($env:TRAEFIK_DASHBOARD_HOST) { $knownDomains += $env:TRAEFIK_DASHBOARD_HOST }
        if ($env:DEMO_HOST) { $knownDomains += $env:DEMO_HOST }
        if ($knownDomains.Count -gt 0) { $Domains = $knownDomains }
    }
    if ($Domains.Count -eq 0) { $Domains = @("traefik.home.arpa", "demo.home.arpa") }
}

Write-Host "# Додайте наступні рядки у файл hosts:" -ForegroundColor Cyan
Write-Host "# Windows: C:\Windows\System32\drivers\etc\hosts" -ForegroundColor Cyan
Write-Host "# Linux/macOS: /etc/hosts" -ForegroundColor Cyan
Write-Host ""

foreach ($d in $Domains) {
    Write-Host "127.0.0.1`t$d" -ForegroundColor Green
}

Write-Host ""
Write-Host "Для застосування на Windows (адміністратор):" -ForegroundColor Yellow
Write-Host "  notepad C:\Windows\System32\drivers\etc\hosts" -ForegroundColor Yellow
Write-Host "Для застосування на Linux:" -ForegroundColor Yellow
Write-Host "  sudo sh -c 'echo \"127.0.0.1 $($Domains[0])\" >> /etc/hosts'" -ForegroundColor Yellow
