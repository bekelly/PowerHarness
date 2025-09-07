# PowerHarnessDebug.ps1

param (
    [string]$ScriptToRun
)

Write-Output "Resetting PowerHarness module"
Remove-Module PowerHarness -Force -ErrorAction SilentlyContinue
Remove-Module phLogger -Force -ErrorAction SilentlyContinue
Remove-Module phUtil -Force -ErrorAction SilentlyContinue
Remove-Module phEmailer -Force -ErrorAction SilentlyContinue
Remove-Module phSQL -Force -ErrorAction SilentlyContinue


Write-Output "Launching script: $ScriptToRun"
. $ScriptToRun