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
    $ph.Logger.Info("This is a more indented info message.`nIt's also a log statement with multiple lines.`nLine 3.`nLine 4.")
    $ph.Logger.IndentDecrease()
    $ph.Logger.Info("Back to previous indent level.")
    $ph.Logger.IndentDecrease()
    $ph.Logger.Error("This is a sample error message")

    $ph.SQL.SetConnection($ph.Config.sqlConnection)
    $accountList = $ph.SQL.ExecReaderToHtmlTable("SELECT * FROM dbo.Account")
    # $ph.Logger.Debug($accountList)
    $body = $ph.emailer.ApplyDefaultTemplate($accountList)
    # $ph.Logger.Debug($body)
    # Write-Host $body
    $ph.Emailer.Send("Test email from PowerHarness", $body, $ph.Config.notifyEmail)
})