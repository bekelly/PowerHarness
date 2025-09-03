# PowerHarnessDebug.ps1

param (
    [string]$ScriptToRun
)

Write-Host "Resetting PowerHarness module"
Remove-Module PowerHarness -Force -ErrorAction SilentlyContinue
Remove-Module phLogger -Force -ErrorAction SilentlyContinue
Remove-Module phUtil -Force -ErrorAction SilentlyContinue
Remove-Module phEmailer -Force -ErrorAction SilentlyContinue
Remove-Module phSQL -Force -ErrorAction SilentlyContinue


Write-Host "Launching script: $ScriptToRun"
. $ScriptToRun