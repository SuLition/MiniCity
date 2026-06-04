param(
    [Parameter(Mandatory = $true)][string]$HookName
)

$ErrorActionPreference = "Stop"

$projectRoot = (& git rev-parse --show-toplevel 2>$null).Trim()
if (-not $projectRoot) {
    exit 0
}

$hookPath = Join-Path $projectRoot (".claude\hooks\" + $HookName)
if (-not (Test-Path -LiteralPath $hookPath)) {
    exit 0
}

$bash = "C:\Program Files\Git\bin\bash.exe"
if (-not (Test-Path -LiteralPath $bash)) {
    exit 0
}

$inputText = [Console]::In.ReadToEnd()
$unixHookPath = $hookPath.Replace("\", "/")
$command = "bash '$unixHookPath'"

Push-Location $projectRoot
try {
    if ([string]::IsNullOrEmpty($inputText)) {
        & $bash -lc $command
    } else {
        $inputText | & $bash -lc $command
    }
    exit $LASTEXITCODE
} finally {
    Pop-Location
}
