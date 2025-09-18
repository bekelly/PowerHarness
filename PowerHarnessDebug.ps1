# PowerHarnessDebug.ps1

param (
    [string]$ScriptToRun
)

Write-Host "Debug Harness Launching script: $ScriptToRun" -ForegroundColor White -BackgroundColor DarkGreen
# . $ScriptToRun
Start-Process powershell -ArgumentList "-NoExit", "-File", $ScriptToRun