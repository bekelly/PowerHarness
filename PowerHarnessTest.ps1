#--------------------------------------------------------------------------------------------------
# PowerHarness very basic starter test script
#--------------------------------------------------------------------------------------------------
$ErrorActionPreference = 'Stop'
Import-Module "$PSScriptRoot\PowerHarness\PowerHarness.psm1"
$ph = Get-PowerHarness -scriptPath $MyInvocation.MyCommand.Path

$ph.RunScript({
	$ph.Logger.Info("Hello World from PowerHarnessTest!")
    $ph.Logger.Debug("This log is not important.")
    $ph.Logger.IndentIncrease()
    $ph.Logger.Info("This is an indented info message.")
    $ph.Logger.IndentIncrease()
    $ph.Logger.Info("This is a more indented info message.")
    $ph.Logger.IndentDecrease()
    $ph.Logger.Info("Back to previous indent level.")
    $ph.Logger.IndentDecrease()
    $ph.Logger.Error("This is a sample error message")
})