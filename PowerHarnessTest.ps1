#--------------------------------------------------------------------------------------------------
# this is my PowerHarness test script
#--------------------------------------------------------------------------------------------------
$ErrorActionPreference = 'Stop'
Import-Module "$PSScriptRoot\PowerHarness\PowerHarness.psm1"
$ph = Get-PowerHarness -scriptPath $MyInvocation.MyCommand.Path

$ph.RunScript({
	$ph.Logger.Info("Hello World from PowerHarnessTest!")
    $ph.Logger.Debug("This log is not important.")
    $ph.Logger.Debug("This log is ALSO not important.  Maybe even less important than the last one.")
    $ph.Logger.Error("Oh no!  My asses!")
})