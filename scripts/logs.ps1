<#
.SYNOPSIS
    Показує логи docker-local-hosting.
.PARAMETER Service
    Ім'я сервісу (traefik, demo, bootstrap, docker-socket-proxy). Якщо не вказано — всі.
.PARAMETER Lines
    Кількість рядків (за замовчуванням 50).
.PARAMETER Follow
    Стежити за логами в реальному часі.
.EXAMPLE
    .\scripts\logs.ps1
    .\scripts\logs.ps1 traefik -Lines 100
    .\scripts\logs.ps1 demo -Follow
#>

param(
    [string]$Service,
    [int]$Lines = 50,
    [switch]$Follow
)

$ErrorActionPreference = "Continue"
$rootDir = Resolve-Path -Path "$PSScriptRoot\.."
Set-Location $rootDir

$argsList = @("logs", "--tail=$Lines")
if ($Follow) { $argsList += "-f" }
if ($Service) { $argsList += $Service }

docker compose @argsList
