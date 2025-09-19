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
    [phSQL]$SQL

    PowerHarness([string]$scriptPath) {
        $this.ScriptName = [System.IO.Path]::GetFileName($scriptPath)
        $this.ScriptRoot = [System.IO.Path]::GetDirectoryName($scriptPath)
        $this.Util = [phUtil]::new()
    }

    [void] RunScript([ScriptBlock]$MainFunction) {

        #------------------------------------------------------------------------------------------
        # just who do we think we are? (get the current version number)
        #------------------------------------------------------------------------------------------
        $version = $this.GetCurrentVersion()

        #------------------------------------------------------------------------------------------
        # initialization and welcome
        #------------------------------------------------------------------------------------------
        $timestamp = Get-Date -Format "yyyy-MM-dd hh:mm:ss tt"
        # Write-Host "Initializing PowerHarness for $($this.ScriptName) [$timestamp]"
        # Write-Host "Script path: $($this.ScriptRoot)"

        #------------------------------------------------------------------------------------------
        # get paths all set up
        #------------------------------------------------------------------------------------------
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($this.ScriptName)

        $logPath = Join-Path $this.ScriptRoot "log/${baseName}.log"

        #------------------------------------------------------------------------------------------
        # load configuration
        #------------------------------------------------------------------------------------------
        $this.Config = $this.GetConfig($baseName, $logPath)

        #------------------------------------------------------------------------------------------
        # initialize subsystems
        #------------------------------------------------------------------------------------------
        $this.Logger = [phLogger]::new($this.Config.logger)
        $this.Emailer = [phEmailer]::new($this.Config.emailer)
        $this.SQL = [phSQL]::new($this.Config.sql, $this.Logger, $this.Util)

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
        }
        catch {
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
                $body = $this.Emailer.ApplyDefaultTemplate($bodyContent)
                $to = $this.Config.notifyEmail
                if ($to) {
                    try {
                        $this.Emailer.Send($subject, $body, $to)
                        $this.Logger.Info("Error notification sent to $to.")
                    }
                    catch {
                        $this.Logger.Info("Failed to send error notification: $_")
                    }
                }
                else {
                    $this.Logger.Info("No notifyEmail configured, skipping error notification.")
                }
            }
        }
        else {
            $this.Logger.Info("Error notifications are disabled for this script.")
        }

        #------------------------------------------------------------------------------------------
        # if the boss wants us to write the log to the database, we can try...?
        #------------------------------------------------------------------------------------------
        try {
            $sqlCommand = "EXEC WriteLogRecord @ScriptName, @LogContent;"
            $params = @{ScriptName = $this.ScriptName; LogContent = $this.Logger.GetLogContent() }
            $this.SQL.SetConnection($this.Config.Logger.logDatabase)
            $this.SQL.ExecNonQuery($sqlCommand, $params)
        }
        catch {
            $this.Logger.Error("Error writing log to database: $_")
        }
    }

    #----------------------------------------------------------------------------------------------
    # GetCurrentVersion
    #
    # reads the current version of PowerHarness from the installed module or the psd1 file
    # (this is massively over-engineered, but it makes me happy)
    #----------------------------------------------------------------------------------------------
    [string] GetCurrentVersion() {

        $version = "?.?.?.?"
        try {
            $moduleInfo = Get-InstalledModule PowerHarness -ErrorAction Stop
            $version = $moduleInfo.Version
        }
        catch {
            try {
                $psd1Path = Join-Path $PSScriptRoot "PowerHarness.psd1"
                if (Test-Path $psd1Path) {
                    try {
                        $psd1Content = Get-Content $psd1Path -Raw
                        if ($psd1Content -match "ModuleVersion\s*=\s*'([^']+)'") {
                            $version = $matches[1]
                        }
                        else {
                            $version = "Unknown Version"
                        }
                    }
                    catch {
                        $version = "Unknown Version"
                    }
                }
                else {
                    $version = "Unknown Version"
                }
            }
            catch {
                $version = "Unknown Version"
            }
        }

        return $version

    }

    #----------------------------------------------------------------------------------------------
    # GetConfig
    #----------------------------------------------------------------------------------------------
    Hidden [PSCustomObject] GetConfig([string]$basename, [string]$logPath) {

        #------------------------------------------------------------------------------------------
        # get paths all set up
        #------------------------------------------------------------------------------------------
        $systemDefaultsPath = Join-Path $PSScriptRoot "resources/Defaults.json"
        $userDefaultsPath = Join-Path $this.ScriptRoot "cfg/Defaults.json"
        $configPath = Join-Path $this.ScriptRoot "cfg/${baseName}.json"

        #------------------------------------------------------------------------------------------
        # we've got to return something, so let's at least make sure we have something to return
        #------------------------------------------------------------------------------------------
        $systemDefaultCfg = [PSCustomObject]@{}
        $userDefaultCfg = [PSCustomObject]@{}
        $scriptCfg = [PSCustomObject]@{}
        $finalCfg = [PSCustomObject]@{}

        #------------------------------------------------------------------------------------------
        # load system defaults
        #------------------------------------------------------------------------------------------
        if (Test-Path $systemDefaultsPath) {
            $systemDefaultCfg = Get-Content $systemDefaultsPath | ConvertFrom-Json
        }

        if (Test-Path $userDefaultsPath) {
            $userDefaultCfg = Get-Content $userDefaultsPath | ConvertFrom-Json
        }

        if (Test-Path $configPath) {
            $scriptCfg = Get-Content $configPath | ConvertFrom-Json
        }

        $finalCfg = $this.Util.MergeJsonObjects($systemDefaultCfg, $userDefaultCfg)
        $finalCfg = $this.Util.MergeJsonObjects($finalCfg, $scriptCfg)

        if (-not $finalCfg.logger.logPath) {
            $finalCfg.logger | Add-Member -MemberType NoteProperty -Name logPath -Value $logPath
        }

        if (-not ($finalCfg -is [psobject])) {
            $finalCfg = $finalCfg | ConvertTo-Json | ConvertFrom-Json
        }

        return $finalCfg
    }
}

function Get-PowerHarness {
    param (
        [string]$scriptPath
    )
    return [PowerHarness]::new($scriptPath)
}

Export-ModuleMember -Function Get-PowerHarness