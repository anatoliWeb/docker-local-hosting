& (Join-Path (Resolve-Path "$PSScriptRoot\..") "scripts\ensure-env.ps1")
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& (Join-Path $PSScriptRoot "preflight.ps1")
exit $LASTEXITCODE
