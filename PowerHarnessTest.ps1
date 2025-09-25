#--------------------------------------------------------------------------------------------------
# PowerHarness very basic starter test script
#--------------------------------------------------------------------------------------------------
$ErrorActionPreference = 'Stop'
Import-Module "$PSScriptRoot\PowerHarness\PowerHarness.psm1"
$ph = Get-PowerHarness -scriptPath $MyInvocation.MyCommand.Path

$ph.RunScript({

        #----------------------------------------------------------------------------------------------
        # logging test
        #----------------------------------------------------------------------------------------------
        if ($ph.Config.logTestEnabled) {
            $ph.Logger.Info("Hello World from PowerHarnessTest!")
            $ph.Logger.Debug("This log is not important.")
            $ph.Logger.IndentIncrease()
            $ph.Logger.Info("This is an indented info message.")
            $ph.Logger.IndentIncrease()
            $ph.Logger.Info("This is a more indented info message.`nIt's also a log statement with multiple lines.`nLine 3.`nLine 4.")
            $ph.Logger.IndentDecrease()
            $ph.Logger.Info("Back to previous indent level.")
            $ph.Logger.IndentDecrease($true)
        }

        #----------------------------------------------------------------------------------------------
        # sql test
        #----------------------------------------------------------------------------------------------
        if ($ph.Config.sqlTestEnabled) {
            $ph.SQL.SetConnection($ph.Config.sqlConnection)
            $accountList = $ph.SQL.ExecReaderToHtmlTable("SELECT * FROM dbo.Account")
            # $accountList = $ph.SQL.ExecNonQuery("SELECT * FROM dbo.Account")
            # $ph.Logger.Debug($accountList)
            $body = $ph.Emailer.Templater.Reset().AddPlain($accountList)
            $ph.Logger.Debug($body)
            # $ph.Emailer.Send("Test email from PowerHarness", $body, $ph.Config.notifyEmail)
        }

        #----------------------------------------------------------------------------------------------
        # emailer test
        #----------------------------------------------------------------------------------------------
        if ($ph.Config.emailTestEnabled) {
            $ph.Logger.Info("Sending test email to $($ph.Config.notifyEmail)")

            $ph.Emailer.Templater.Reset(). `
                AddTitle("PowerHarness Test Email"). `
                AddTitleChipBlack("Title Chip Black"). `
                AddTitleChipBlue("Title Chip Blue"). `
                AddTitleChipGreen("Title Chip Green"). `
                AddTitleChipRed("Title Chip Red"). `
                AddPlain("This is a plain text paragraph."). `
                AddCode("sql", "SELECT * FROM dbo.Account;"). `
                AddMonoBlock("This is a mono block of text.`nIt can have multiple lines.`nLine 3.`nLine 4."). `
                AddTitleChipBlue("Current Log").AddLogContent($ph.Logger.GetHtmlLog())

            $ph.Emailer.SendFromTemplate("Test email from PowerHarness", $ph.Config.notifyEmail)
        }

        #----------------------------------------------------------------------------------------------
        # error test -- in case we want to test error handling, error emails, etc.
        #----------------------------------------------------------------------------------------------
        if ($ph.Config.errorTestEnabled) {
            $ph.Logger.Error("A FAUX ERROR HAS OCCURRED.")
        }

        #----------------------------------------------------------------------------------------------
        # let 'em know we're all done
        #----------------------------------------------------------------------------------------------
        $ph.Logger.Info("All tests completed.")

    })