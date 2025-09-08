# PowerHarnessDebug.ps1

param (
    [string]$ScriptToRun
)

Write-Output "Resetting PowerHarness module"
Remove-Module PowerHarness -Force -ErrorAction SilentlyContinue

Write-Output "Launching script: $ScriptToRun"
. $ScriptToRun