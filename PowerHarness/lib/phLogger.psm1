$ErrorActionPreference = 'Stop'

class phLogger {
    [PSCustomObject]$Config
    [int]$ErrorCount = 0
    [System.Text.StringBuilder]$HtmlLog
    [int]$IndentLevel = 0
    [string]$IndentStr = "  "

    [void] WriteToConsole([string]$message) {
        if ($this.Config.writeConfigToConsole)
        {
            Write-Host $message
        }
    }

    phLogger([PSCustomObject]$config) {

        #------------------------------------------------------------------------------------------
        # initialize our bits
        #------------------------------------------------------------------------------------------
        $this.Config = $config
        $this.HtmlLog = [System.Text.StringBuilder]::new()

        #------------------------------------------------------------------------------------------
        # log configuration values (if enabled)
        #------------------------------------------------------------------------------------------
        $this.WriteToConsole("phLogger: Log Path = '$($this.Config.LogPath)'")
        $this.WriteToConsole("phLogger: Debug Enabled = $($this.Config.DebugEnabled)")
        $this.WriteToConsole("phLogger: File Logging Enabled = $($this.Config.fileLogEnabled)")
        $this.WriteToConsole("phLogger: Console Logging Enabled = $($this.Config.consoleLogEnabled)")

        #------------------------------------------------------------------------------------------
        # detect if LogPath is relative
        #------------------------------------------------------------------------------------------
        if (-not [System.IO.Path]::IsPathRooted($this.Config.LogPath)) {
            $this.WriteToConsole("phLogger: Log Path is relative, converting to absolute path.")
            $this.Config.LogPath = Join-Path $PSScriptRoot $this.Config.LogPath
            $this.WriteToConsole("phLogger: Log Path is now '$($this.Config.LogPath)'")
        }

        #------------------------------------------------------------------------------------------
        # if the log path doesn't exist, try to create it
        #------------------------------------------------------------------------------------------
        $logDir = [System.IO.Path]::GetDirectoryName($this.Config.LogPath)
        if (-not (Test-Path $logDir)) {
            $this.WriteToConsole("phLogger: Log directory '$logDir' does not exist, creating it.")
            New-Item -ItemType Directory -Path $logDir | Out-Null
        }

        #------------------------------------------------------------------------------------------
        # trim log if oversized
        #------------------------------------------------------------------------------------------
        if (Test-Path $this.Config.LogPath) {
            $currentSize = (Get-Item $this.Config.LogPath).length / 1024
            if ($currentSize -gt $this.Config.MaxSizeKB) {
                $this.WriteToConsole("phLogger: Log file exceeds max size of $($this.Config.MaxSizeKB)KB, trimming.")
                $lines = Get-Content $this.Config.LogPath
                while ($currentSize -gt $this.Config.MaxSizeKB -and $lines.Count -gt 0) {
                    $lines = $lines[1..($lines.Count - 1)]
                    $currentSize = ($lines -join "`n").Length / 1024
                }
                $lines | Set-Content $this.Config.LogPath
            }
        }
    }

    hidden [void]Log([string]$Level, [string]$Message) {

        $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        $indentText = $this.IndentStr * ($this.IndentLevel)
        $levelPadded = "$Level".PadLeft(5)

        foreach ($line in $Message -split "`r?`n") {
            $logLine = "$timestamp [$levelPadded] $indentText$line"

            # Console output (only if enabled in config)
            if ($this.Config.consoleLogEnabled) {
            if ($Level -eq 'ERROR') {
                Write-Host $logLine -ForegroundColor Red
            } elseif ($Level -eq 'DEBUG') {
                Write-Host $logLine -ForegroundColor Cyan
            } else {
                Write-Host $logLine
            }
            }

            # File output
            if ($this.Config.fileLogEnabled) {
            Add-Content -Path $this.Config.LogPath -Value $logLine
            }

            # HTML log accumulation
            $escaped = [System.Net.WebUtility]::HtmlEncode($logLine)
            $this.HtmlLog.AppendLine("<div class='log-$($Level.ToLower())'>$escaped</div>") | Out-Null
        }

        if ($Level -eq 'ERROR') {
            $this.ErrorCount++
        }
    }

    [void] Debug([string]$Message) {
        if ($this.Config.DebugEnabled) {
            $this.Log("DEBUG", $Message)
        }
    }

    [void] Info([string]$Message) {
        $this.Log("INFO", $Message)
    }

    [void] Error([string]$Message) {
        $this.Log("ERROR", $Message)
    }

    [string] GetHtmlLog() {
        return $this.HtmlLog.ToString()
    }

    [void] IndentIncrease() {
        $this.IndentLevel++
    }

    [void] IndentDecrease() {
        if ($this.IndentLevel -gt 0) {
            $this.IndentLevel--
        }
    }

    [void] SetIndentStr([string]$str) {
        $this.IndentStr = $str
    }

    [void] ResentIndentStr() {
        $this.IndentStr = "  "
    }
}