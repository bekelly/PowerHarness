using module '.\phLogger.psm1'
using module '.\phEmailTemplater.psm1'
$ErrorActionPreference = 'Stop'

class phEmailer {
    [PSCustomObject] $Config
    [phLogger] $Logger
    [System.Net.Mail.SmtpClient] $SmtpClient
    [System.Net.Mail.MailAddress] $FromAddress
    [phEmailTemplater] $Templater = [phEmailTemplater]::new()

    phEmailer([PSCustomObject]$config, [phLogger]$logger) {
        $this.Config = $config
        $this.Logger = $logger
        $this.SmtpClient = [System.Net.Mail.SmtpClient]::new($config.smtpServer, $config.smtpPort)
        $this.SmtpClient.EnableSsl = $config.enableSSL
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

        try {
            $this.ArchiveEmail($Body)
        }
        catch {
            $this.Logger.Error("Failed to archive email: $_")
        }

        $this.SmtpClient.Send($mail)
    }

    Hidden [void] ArchiveEmail([string]$body) {
        $loggerPath = $this.Logger.Config.LogPath
        if ($this.Config.archiveEmail) {
            if (-not $loggerPath -or [string]::IsNullOrWhiteSpace($loggerPath)) {
                throw "Logger.LogPath is not set or is invalid."
            }
            $logDir = [System.IO.Path]::GetDirectoryName($loggerPath)
            if (-not $logDir) {
                throw "Logger.LogPath does not contain a valid directory."
            }
            $archiveDir = Join-Path -Path $logDir -ChildPath "Emails"
            if (-not (Test-Path $archiveDir)) {
                New-Item -Path $archiveDir -ItemType Directory | Out-Null
            }
            $timestamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
            $logFileName = [System.IO.Path]::GetFileNameWithoutExtension($loggerPath)
            $filePath = Join-Path $archiveDir "${logFileName}_Email_$timestamp.html"
            $this.Logger.Debug("Archiving email to $filePath")
            $body | Out-File -FilePath $filePath -Encoding UTF8

            # Clean up old archives
            $daysToKeep = if ($this.Config.archiveDaysToKeep) { $this.Config.archiveDaysToKeep } else { 30 }
            Get-ChildItem -Path $archiveDir -Filter "*_Email_*.html" | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$daysToKeep) } | Remove-Item
        }
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