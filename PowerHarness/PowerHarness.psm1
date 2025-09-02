#--------------------------------------------------------------------------------------------------
# PowerHarness
#
# version 0.9
# by Brian Kelly
#--------------------------------------------------------------------------------------------------
# PowerHarness is a PowerShell framework for running scripts with logging and email notifications.
#
# It provides a structured way to execute scripts, log their output, and send notifications on
# errors.
#--------------------------------------------------------------------------------------------------
using module ".\lib\phUtil.psm1"
using module ".\lib\phLogger.psm1"
using module ".\lib\phEmailer.psm1"
using module ".\lib\phSQL.psm1"
$ErrorActionPreference = 'Stop'

class PowerHarness {
    [string]$ScriptName
    [string]$ScriptRoot
    [object]$Config
    [phLogger]$Logger
    [phEmailer]$Emailer
    [phUtil]$Util

    PowerHarness([string]$scriptPath) {
        $this.ScriptName = [System.IO.Path]::GetFileName($scriptPath)
        $this.ScriptRoot = [System.IO.Path]::GetDirectoryName($scriptPath)
        $this.Util = [phUtil]::new()
    }

    [void] RunScript([ScriptBlock]$MainFunction) {
        
        #------------------------------------------------------------------------------------------
        # initialization and welcome
        #------------------------------------------------------------------------------------------
        $version = "0.9.3"
        $timestamp = Get-Date -Format "yyyy-MM-dd hh:mm:ss tt"
        Write-Host "Initializing PowerHarness for $($this.ScriptName) [$timestamp]"
        Write-Host "Script path: $($this.ScriptRoot)"

        #------------------------------------------------------------------------------------------
        # get paths all set up
        #------------------------------------------------------------------------------------------
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($this.ScriptName)
        $defaultConfigPath = Join-Path $this.ScriptRoot "cfg/PowerHarnessDefaults.json"
        $configPath = Join-Path $this.ScriptRoot "cfg/${baseName}.json"
        $logPath = Join-Path $this.ScriptRoot "log/${baseName}.log"

        #------------------------------------------------------------------------------------------
        # load configuration
        #------------------------------------------------------------------------------------------
        if (Test-Path $defaultConfigPath) {
            $defaultCfg = Get-Content $defaultConfigPath | ConvertFrom-Json
        } else {
            Write-Host "Default config file not found at $defaultConfigPath, loading empty defaults."
            $defaultCfg = [PSCustomObject]@{}
        }

        if (Test-Path $configPath) {
            $scriptConfig = Get-Content $configPath | ConvertFrom-Json
        } else {
            Write-Host "Config file not found at $configPath, loading defaults."
            $scriptConfig = [PSCustomObject]@{}
        }

        $cfg = $this.Util.MergeJsonObjects($defaultCfg, $scriptConfig)

        if (-not $cfg.logger.logPath) {
            $cfg.logger | Add-Member -MemberType NoteProperty -Name logPath -Value $logPath
        }

        if (-not ($cfg -is [psobject])) {
            $cfg = $cfg | ConvertTo-Json | ConvertFrom-Json
        }

        $this.Config = $cfg
        
        #------------------------------------------------------------------------------------------
        # initialize subsystems
        #------------------------------------------------------------------------------------------
        $this.Logger = [phLogger]::new($cfg.logger)
        $this.Emailer = [phEmailer]::new($cfg.emailer)

        #------------------------------------------------------------------------------------------
        # welcome everyone
        #------------------------------------------------------------------------------------------
        $this.Logger.Info("====== $($this.ScriptName) - PowerHarness v$version =============================")

        #------------------------------------------------------------------------------------------
        # if we're supposed to log the config, go ahead and do that now
        #------------------------------------------------------------------------------------------
        if ($this.Config.logConfiguration) {
            $this.Logger.Info("")
            $this.Logger.Info("Script configuration:")
            $this.Logger.IndentIncrease()
            $this.Util.LogObject($this.Config, $this.Logger)
            $this.Logger.IndentDecrease()
            $this.Logger.Info("")
        }

        #------------------------------------------------------------------------------------------
        # do the actual work we came here to do
        #------------------------------------------------------------------------------------------
        try {
            & $MainFunction
            $this.Logger.Info("Script completed successfully.")
        } catch {
            $this.Logger.Error("Exception running main function: $_")
        }

        #------------------------------------------------------------------------------------------
        # check for errors and send notification if enabled
        #------------------------------------------------------------------------------------------
        if ($this.config.errorNotificationEnabled) {
            if ($this.Logger.ErrorCount -gt 0) {
                $logHtml = $this.Logger.GetHtmlLog()
                $subject = "$($this.ScriptName) error report [$timestamp]"
                $bodyContent = "<div class='code'>$logHtml</div>"
                $templatePath = Join-Path $this.ScriptRoot "tpl/$($this.Config.notificationTemplate)"
                $this.Logger.Debug("Using notification template at $templatePath")
                if (Test-Path $templatePath) {
                    $template = Get-Content $templatePath -Raw
                    $body = $template -replace '%message%', [System.Text.RegularExpressions.Regex]::Escape($bodyContent) -replace '\\n', "`n"
                    $body = $template -replace '%message%', $bodyContent
                } else {
                    $this.Logger.Info("Notification template not found at $templatePath, using raw log content.")
                    $body = $bodyContent
                }
                $to = $cfg.notifyEmail
                if ($to) {
                    try {
                        $this.Emailer.Send($subject, $body, $to)
                        $this.Logger.Info("Error notification sent to $to.")
                    } catch {
                        $this.Logger.Info("Failed to send error notification: $_")
                    }
                } else {
                    $this.Logger.Info("No notifyEmail configured, skipping error notification.")
                }
            }
        } else {
            $this.Logger.Info("Error notifications are disabled for this script.")
        }
    }
}

function Get-PowerHarness {
    param (
        [string]$scriptPath
    )
    return [PowerHarness]::new($scriptPath)
}

Export-ModuleMember -Function Get-PowerHarness