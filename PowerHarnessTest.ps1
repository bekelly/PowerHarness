#--------------------------------------------------------------------------------------------------
# PowerHarness very basic starter test script
#--------------------------------------------------------------------------------------------------
$ErrorActionPreference = 'Stop'
Import-Module "$PSScriptRoot\PowerHarness\PowerHarness.psm1"
$ph = Get-PowerHarness -scriptPath $MyInvocation.MyCommand.Path

$ph.RunScript({
	$ph.Logger.Info("Hello World from PowerHarnessTest!")
    $ph.Logger.Debug("This log is not important.")
    $ph.Logger.Error("This is a sample error message")
})