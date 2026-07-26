<#
.SYNOPSIS
    Генерує TLS-сертифікати для локальних доменів через mkcert.
.DESCRIPTION
    Читає TLS_CERT_FILE, TLS_KEY_FILE, MKCERT_DOMAINS із .env.
    Якщо сертифікати вже існують і дійсні — пропускає.
    Створює бекап старих сертифікатів.
    Для Windows Server використовує --install.
.EXAMPLE
    .\scripts\generate-certs.ps1
#>

$ErrorActionPreference = "Stop"
$rootDir = Resolve-Path -Path "$PSScriptRoot\.."

# Завантаження змінних із .env
$envFile = Join-Path $rootDir ".env"
if (-not (Test-Path $envFile)) {
    Write-Host "[ПОМИЛКА] .env не знайдено. Скопіюйте .env.example у .env." -ForegroundColor Red
    exit 1
}
Get-Content $envFile | ForEach-Object {
    if ($_ -match '^([^#=]+)=(.+)$') { Set-Item -Path "env:$($matches[1])" -Value $matches[2] 2>$null }
}

$certRel = $env:TLS_CERT_FILE; if (-not $certRel) { $certRel = "./certs/home.arpa.pem" }
$keyRel  = $env:TLS_KEY_FILE;  if (-not $keyRel)  { $keyRel = "./certs/home.arpa-key.pem" }
$domains = $env:MKCERT_DOMAINS; if (-not $domains) { $domains = "home.arpa *.home.arpa" }

$certFile = [System.IO.Path]::GetFullPath((Join-Path $rootDir $certRel.Replace("./", "")))
$keyFile  = [System.IO.Path]::GetFullPath((Join-Path $rootDir $keyRel.Replace("./", "")))
$certsDir = [System.IO.Path]::GetDirectoryName($certFile)

if (-not (Test-Path $certsDir)) { New-Item -ItemType Directory -Path $certsDir -Force | Out-Null }

# Перевірка mkcert
$mkcert = Get-Command "mkcert" -ErrorAction SilentlyContinue
if (-not $mkcert) {
    Write-Host "[ПОМИЛКА] mkcert не знайдено. Встановіть: https://github.com/FiloSottile/mkcert" -ForegroundColor Red
    exit 1
}

# Перевірка, чи існують валідні сертифікати
$certExists = Test-Path $certFile
$keyExists  = Test-Path $keyFile
$skip = $false

if ($certExists -and $keyExists) {
    $certSize = (Get-Item $certFile).Length
    $keySize  = (Get-Item $keyFile).Length
    if ($certSize -gt 0 -and $keySize -gt 0) {
        try {
            $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 $certFile
            $notAfter = $cert.NotAfter
            $daysLeft = ($notAfter - (Get-Date)).Days
            if ($daysLeft -gt 30) {
                Write-Host "[OK] Сертифікати дійсні ще $daysLeft днів, пропускаю генерацію." -ForegroundColor Green
                $skip = $true
            } elseif ($daysLeft -gt 0) {
                Write-Host "[УВАГА] Сертифікати скоро прострочаться ($daysLeft днів)." -ForegroundColor Yellow
            } else {
                Write-Host "[УВАГА] Сертифікати прострочено." -ForegroundColor Yellow
            }
            $cert.Dispose()
        } catch {
            Write-Host "[УВАГА] Не вдалося перевірити сертифікат, генерую заново." -ForegroundColor Yellow
        }
    }
}

if (-not $skip) {
    # Бекап старих сертифікатів
    if ($certExists -or $keyExists) {
        $backupDir = Join-Path $certsDir "backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
        if ($certExists) { Move-Item $certFile -Destination $backupDir -Force }
        if ($keyExists)  { Move-Item $keyFile -Destination $backupDir -Force }
        Write-Host "[INFO] Старі сертифікати переміщено до $backupDir" -ForegroundColor Cyan
    }

    # Генерація
    $domainArgs = $domains -split "\s+"
    $installFlag = @()
    $isNano = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name "EditionID" 2>$null).EditionID -match "Server"
    if ($isNano) { $installFlag = @("--install") }

    Write-Host "Генерую сертифікати для: $domains" -ForegroundColor Cyan
    & $mkcert.Path -cert-file $certFile -key-file $keyFile @installFlag @domainArgs

    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Сертифікати створено:" -ForegroundColor Green
        Write-Host "  Сертифікат: $certFile" -ForegroundColor Green
        Write-Host "  Ключ:       $keyFile" -ForegroundColor Green
    } else {
        Write-Host "[ПОМИЛКА] Генерація сертифікатів не вдалася." -ForegroundColor Red
        exit 1
    }
}
