# PowerHarnessDebug.ps1

param (
    [string]$ScriptToRun
)

Write-Host "Resetting PowerHarness module"
Remove-Module PowerHarness -Force -ErrorAction SilentlyContinue

Write-Host "Launching script: $ScriptToRun"
. $ScriptToRun