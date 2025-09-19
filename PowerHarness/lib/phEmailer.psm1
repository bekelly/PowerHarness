$ErrorActionPreference = 'Stop'

class phEmailer {
    [System.Net.Mail.SmtpClient] $SmtpClient
    [System.Net.Mail.MailAddress] $FromAddress

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

    [string] ApplyTemplate([string]$templatePath, [hashtable]$placeholders) {

        #------------------------------------------------------------------------------------------
        # validate the template path
        #------------------------------------------------------------------------------------------
        if (-not (Test-Path $templatePath)) {
            throw "Template file not found: $templatePath"
        }

        #------------------------------------------------------------------------------------------
        # load the file
        #------------------------------------------------------------------------------------------
        $templateContent = Get-Content -Path $templatePath -Raw

        #------------------------------------------------------------------------------------------
        # do the replacements
        #------------------------------------------------------------------------------------------
        foreach ($key in $placeholders.Keys) {
            $placeholder = "%$key%"
            $value = $placeholders[$key]
            $templateContent = $templateContent.Replace($placeholder, $value)
        }

        #------------------------------------------------------------------------------------------
        # give 'em what we've got
        #------------------------------------------------------------------------------------------
        return $templateContent

    }

    [string] ApplyDefaultTemplate([string]$bodyContent) {
        $templatePath = Join-Path $PSScriptRoot "../resources/EmailTemplate.html"
        return $this.ApplyTemplate($templatePath, @{ message = $bodyContent })
    }
}