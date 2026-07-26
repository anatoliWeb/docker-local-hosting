<#
.SYNOPSIS
    Створює .env з .env.example лише за його відсутності.
#>

$ErrorActionPreference = "Stop"
$rootDir = Resolve-Path -Path "$PSScriptRoot\.."
$envExample = Join-Path $rootDir ".env.example"
$envFile = Join-Path $rootDir ".env"

if (-not (Test-Path -LiteralPath $envExample -PathType Leaf)) {
    Write-Host "[ПОМИЛКА] Файл .env.example відсутній." -ForegroundColor Red
    exit 1
}

if (Test-Path -LiteralPath $envFile -PathType Leaf) {
    Write-Host "Файл .env уже існує" -ForegroundColor Green
    exit 0
}

Copy-Item -LiteralPath $envExample -Destination $envFile -ErrorAction Stop

$ignoredByGit = git -C $rootDir check-ignore -q .env 2>$null
if ($LASTEXITCODE -ne 0) {
    Remove-Item -LiteralPath $envFile -Force
    Write-Host "[ПОМИЛКА] .env не ігнорується Git. Перевірте .gitignore." -ForegroundColor Red
    exit 1
}

Write-Host "Створено .env з .env.example" -ForegroundColor Green
exit 0
