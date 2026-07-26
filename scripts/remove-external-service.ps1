<#
.SYNOPSIS
    Видаляє зовнішній сервіс з Traefik File Provider.
.DESCRIPTION
    Видаляє сервіс з external-services.yaml. Traefik отримує SIGHUP.
.PARAMETER Name
    Ім'я сервісу для видалення.
.PARAMETER Force
    Не питати підтвердження.
.EXAMPLE
    .\scripts\remove-external-service.ps1 -Name camera
    .\scripts\remove-external-service.ps1 -Name camera -Force
#>

param(
    [Parameter(Mandatory=$true)][string]$Name,
    [switch]$Force
)

$ErrorActionPreference = "Stop"
$rootDir = Resolve-Path -Path "$PSScriptRoot\.."
$registryFile = Join-Path $rootDir "config\traefik\dynamic\external-services.yaml"

if (-not (Test-Path $registryFile)) {
    Write-Host "[УВАГА] Registry-файл не знайдено: $registryFile" -ForegroundColor Yellow
    exit 0
}

# Parse existing registry into a hash
$content = Get-Content $registryFile -Raw -Encoding UTF8
$services = @{}
$lines = $content -split "`n" | ForEach-Object { $_.TrimEnd("`r") }
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

if (-not $services.ContainsKey($Name)) {
    Write-Host "[УВАГА] Сервіс '$Name' не знайдено в registry." -ForegroundColor Yellow
    exit 0
}

if (-not $Force) {
    $response = Read-Host "Видалити сервіс '$Name'? (Y/N)"
    if ($response -ne "Y" -and $response -ne "y") { Write-Host "Скасовано." -ForegroundColor Yellow; exit 0 }
}

$services.Remove($Name)

# Write clean YAML
$sb = New-Object System.Text.StringBuilder
$null = $sb.AppendLine("# External services registry")
$null = $sb.AppendLine("# Auto-generated. Do not edit manually.")
$null = $sb.AppendLine("# Use: .\scripts\add-external-service.ps1 .\scripts\remove-external-service.ps1")
$null = $sb.AppendLine("")
$null = $sb.AppendLine("http:")
$null = $sb.AppendLine("  routers:")

$bt = [char]96
$sorted = $services.Keys | Sort-Object
foreach ($key in $sorted) {
    $svcDomain = $services[$key].Domain
    $null = $sb.AppendLine("    $key" + ":")
    $null = $sb.AppendLine("      rule: ""Host($bt$svcDomain$bt)""")
    $null = $sb.AppendLine("      entrypoints:")
    $null = $sb.AppendLine("        - websecure")
    $null = $sb.AppendLine("      service: " + $key)
    $null = $sb.AppendLine("      tls: true")
}

$null = $sb.AppendLine("")
$null = $sb.AppendLine("  services:")

foreach ($key in $sorted) {
    $svcUrl = $services[$key].Url
    $null = $sb.AppendLine("    $key" + ":")
    $null = $sb.AppendLine("      loadBalancer:")
    $null = $sb.AppendLine("        servers:")
    $null = $sb.AppendLine("          - url: ""$svcUrl""")
    $null = $sb.AppendLine("        passHostHeader: true")
}

$yamlContent = $sb.ToString().Replace("`r`n", "`n")

$tempPath = [System.IO.Path]::GetTempFileName()
[System.IO.File]::WriteAllText($tempPath, $yamlContent, [System.Text.UTF8Encoding]::new($false))
Remove-Item $registryFile -Force
Move-Item -Path $tempPath -Destination $registryFile -Force

Write-Host "[OK] Сервіс '$Name' видалено з $registryFile" -ForegroundColor Green
Write-Host ""
Write-Host "Перезавантаження конфігурації Traefik..." -ForegroundColor Cyan
docker compose kill -s HUP traefik 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "[OK] Traefik перезавантажено (SIGHUP). Без restart." -ForegroundColor Green
} else {
    Write-Host "[УВАГА] Не вдалося відправити SIGHUP." -ForegroundColor Yellow
}
