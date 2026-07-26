<#
.SYNOPSIS
    Додає зовнішній сервіс (не Docker) до Traefik через File Provider.
.DESCRIPTION
    Оновлює config/traefik/dynamic/external-services.yaml (єдиний registry-файл).
    Валідує URL і копіює registry у контейнер для File Provider reload на Windows.
.PARAMETER Name
    Унікальне ім'я сервісу.
.PARAMETER Domain
    Домен для доступу.
.PARAMETER Url
    URL бекенда (наприклад, http://192.168.1.50:9000, http://host.docker.internal:9000).
.EXAMPLE
    .\scripts\add-external-service.ps1 -Name camera -Domain camera.home.arpa -Url http://192.168.1.50:9000
#>

param(
    [Parameter(Mandatory=$true)][string]$Name,
    [Parameter(Mandatory=$true)][string]$Domain,
    [Parameter(Mandatory=$true)][string]$Url
)

$ErrorActionPreference = "Stop"
$rootDir = Resolve-Path -Path "$PSScriptRoot\.."
$dynamicDir = Join-Path $rootDir "config\traefik\dynamic"
$registryFile = Join-Path $dynamicDir "external-services.yaml"

if (-not (Test-Path $dynamicDir)) { New-Item -ItemType Directory -Path $dynamicDir -Force | Out-Null }

try {
    $uri = [System.Uri]$Url
    $urlScheme = $uri.Scheme
    $urlHost = $uri.Host
} catch {
    Write-Host "[ПОМИЛКА] Некоректний URL: $Url" -ForegroundColor Red
    exit 1
}
if ($urlScheme -ne "http" -and $urlScheme -ne "https") {
    Write-Host "[ПОМИЛКА] Схема URL має бути http або https." -ForegroundColor Red
    exit 1
}
if ($urlHost -eq "127.0.0.1" -or $urlHost -eq "localhost") {
    Write-Host "[ПОМИЛКА] 127.0.0.1 та localhost з Traefik container означають сам контейнер." -ForegroundColor Red
    Write-Host "  Для Windows host використовуйте: http://host.docker.internal:9000" -ForegroundColor Yellow
    Write-Host "  Для LAN пристрою використовуйте: http://192.168.1.50:9000" -ForegroundColor Yellow
    exit 1
}

$services = @{}
if (Test-Path $registryFile) {
    $content = Get-Content $registryFile -Raw -Encoding UTF8
    $lines = $content -split "`n" | ForEach-Object { $_.TrimEnd("`r") }
    $current = $null
    $mode = ""
    foreach ($line in $lines) {
        if ($line -match '^  routers:\s*$') { $mode = "routers"; continue }
        if ($line -match '^  services:\s*$') { $mode = "services"; continue }
        if ($line -match '^    (\S+):$') {
            $current = $matches[1]
            if (-not $services.ContainsKey($current)) { $services[$current] = @{ Domain = ""; Url = "" } }
        }
        if ($mode -eq "routers" -and $line -match 'rule:\s+"Host\(`(.+?)`\)"') {
            if ($current) { $services[$current].Domain = $matches[1] }
        }
        if ($mode -eq "services" -and $line -match 'url:\s+"(.+)"') {
            if ($current) { $services[$current].Url = $matches[1] }
        }
    }
}

$services[$Name] = @{ Domain = $Domain; Url = $Url }

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
if (Test-Path $registryFile) { Remove-Item $registryFile -Force }
Move-Item -Path $tempPath -Destination $registryFile -Force

Write-Host "[OK] Оновлено $registryFile" -ForegroundColor Green
Write-Host "Сервіс $Name доступний за адресою https://$Domain" -ForegroundColor Green
Write-Host ""
Write-Host "Оновлення File Provider у Traefik..." -ForegroundColor Cyan
docker exec traefik /bin/sh -c "cp /etc/traefik/dynamic/external-services.yaml /etc/traefik/dynamic/.external-services.yaml.tmp && mv /etc/traefik/dynamic/.external-services.yaml.tmp /etc/traefik/dynamic/external-services.yaml"
if ($LASTEXITCODE -eq 0) {
    Write-Host "[OK] File Provider оновлено без recreate Traefik." -ForegroundColor Green
} else {
    Write-Host "[УВАГА] Не вдалося оновити File Provider. Запустіть stack і повторіть команду." -ForegroundColor Yellow
}
Write-Host ""
Write-Host "Додайте в hosts:" -ForegroundColor Yellow
Write-Host "  127.0.0.1 $Domain" -ForegroundColor Yellow
