<#
.SYNOPSIS
    Генерує локальний TLS-сертифікат для home.arpa через mkcert.
.DESCRIPTION
    Скрипт перевіряє наявність mkcert, локального CA,
    створює каталог certs та генерує сертифікат із необхідними доменами.
.EXAMPLE
    .\scripts\generate-certs.ps1
#>

$ErrorActionPreference = "Stop"
$certsDir = Join-Path -Path $PSScriptRoot -ChildPath "..\certs" | Resolve-Path -ErrorAction SilentlyContinue
if (-not $certsDir) {
    $certsDir = Join-Path -Path $PSScriptRoot -ChildPath "..\certs"
    New-Item -ItemType Directory -Path $certsDir -Force | Out-Null
    $certsDir = Resolve-Path -Path $certsDir
}

# Перевірка mkcert
$mkcertPath = Get-Command mkcert -ErrorAction SilentlyContinue
if (-not $mkcertPath) {
    Write-Host "ПОМИЛКА: mkcert не знайдено." -ForegroundColor Red
    Write-Host "" -ForegroundColor Red
    Write-Host "Встановіть mkcert:" -ForegroundColor Yellow
    Write-Host "  1. Завантажте з https://github.com/FiloSottile/mkcert/releases" -ForegroundColor Yellow
    Write-Host "  2. Або через winget: winget install mkcert" -ForegroundColor Yellow
    Write-Host "  3. Або через chocolatey: choco install mkcert" -ForegroundColor Yellow
    Write-Host "" -ForegroundColor Yellow
    Write-Host "Після встановлення запустіть: mkcert -install" -ForegroundColor Yellow
    exit 1
}
Write-Host "mkcert знайдено: $($mkcertPath.Source)" -ForegroundColor Green

# Перевірка локального CA
$caCheck = mkcert -install 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "ПОМИЛКА: Не вдалося встановити локальний CA через mkcert." -ForegroundColor Red
    Write-Host "Спробуйте запустити вручну: mkcert -install" -ForegroundColor Yellow
    exit 1
}

# Отримання шляху до CA
$caPath = mkcert -CAROOT 2>&1
Write-Host "Локальний CA знаходиться за шляхом: $caPath" -ForegroundColor Cyan

# Генерація сертифіката
$certFile = Join-Path -Path $certsDir -ChildPath "home.arpa.pem"
$keyFile = Join-Path -Path $certsDir -ChildPath "home.arpa-key.pem"

Write-Host "Генерую сертифікат для доменів: home.arpa, *.home.arpa" -ForegroundColor Cyan
Write-Host "Увага: wildcard *.home.arpa не покриває вкладені піддомени (наприклад, api.crm.home.arpa)." -ForegroundColor Yellow
Write-Host "Для вкладених піддоменів додайте їх вручну до команди mkcert або використовуйте однорівневі домени." -ForegroundColor Yellow

mkcert -cert-file $certFile -key-file $keyFile "home.arpa" "*.home.arpa"
if ($LASTEXITCODE -ne 0) {
    Write-Host "ПОМИЛКА: Не вдалося згенерувати сертифікат." -ForegroundColor Red
    exit 1
}

Write-Host "" -ForegroundColor Cyan
Write-Host "Сертифікати згенеровано успішно:" -ForegroundColor Green
Write-Host "  Сертифікат: $certFile" -ForegroundColor Green
Write-Host "  Приватний ключ: $keyFile" -ForegroundColor Green
Write-Host "" -ForegroundColor Cyan
Write-Host "ВАЖЛИВО: Приватний ключ не комітьте в Git." -ForegroundColor Yellow
Write-Host "ВАЖЛИВО: Не копіюйте CA private key на інші комп'ютери." -ForegroundColor Yellow
Write-Host "" -ForegroundColor Cyan
Write-Host "Наступні кроки:" -ForegroundColor Cyan
Write-Host "  1. Додайте записи у файл hosts (адміністратор)" -ForegroundColor Cyan
Write-Host "  2. Запустіть: docker compose up -d" -ForegroundColor Cyan
exit 0
