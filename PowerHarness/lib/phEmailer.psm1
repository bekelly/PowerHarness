using module '.\phEmailTemplater.psm1'
$ErrorActionPreference = 'Stop'

class phEmailer {
    [System.Net.Mail.SmtpClient] $SmtpClient
    [System.Net.Mail.MailAddress] $FromAddress
    [phEmailTemplater] $Templater = [phEmailTemplater]::new()

    phEmailer([PSCustomObject]$config) {
        $this.SmtpClient = [System.Net.Mail.SmtpClient]::new($config.smtpServer, $config.smtpPort)
        $this.SmtpClient.EnableSsl = $true
        $this.SmtpClient.Credentials = [System.Net.NetworkCredential]::new($config.username, $config.password)
        $this.FromAddress = [System.Net.Mail.MailAddress]::new($config.fromEmail, $config.fromName)
    }

    [void] Send([string]$Subject, [string]$Body, [string]$ToAddress, [string[]]$CcAddresses = @()) {
        $mail = [System.Net.Mail.MailMessage]::new()
        $mail.From = $this.FromAddress
        $mail.To.Add($ToAddress)

        if ($CcAddresses) {
            foreach ($cc in $CcAddresses) {
                if ($cc) { $mail.CC.Add($cc) }
            }
        }

        $mail.Subject = $Subject
        $mail.Body = $Body
        $mail.IsBodyHtml = $true

        $this.SmtpClient.Send($mail)
    }

    [void] Send([string]$Subject, [string]$Body, [string]$ToAddress) {
        $this.Send($Subject, $Body, $ToAddress, @())
    }

    [void] SendFromTemplate([string]$subject, [string]$toAddress, [string[]]$ccAddresses) {
        $body = $this.Templater.GetBody()
        $this.Send($subject, $body, $toAddress, $ccAddresses)
    }

    [void] SendFromTemplate([string]$subject, [string]$toAddress) {
        $this.SendFromTemplate($subject, $toAddress, @())
    }

}