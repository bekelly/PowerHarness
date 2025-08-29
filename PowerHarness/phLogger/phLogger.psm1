$ErrorActionPreference = 'Stop'

class Logger {
    [PSCustomObject]$Config
    [int]$ErrorCount = 0
    [System.Text.StringBuilder]$HtmlLog

    Logger([PSCustomObject]$config) {
        $this.Config = $config
        $this.HtmlLog = [System.Text.StringBuilder]::new()

        Write-Host "phLogger: Log Path = '$($this.Config.LogPath)'"
        Write-Host "phLogger: Debug Enabled = $($this.Config.DebugEnabled)"
        Write-Host "phLogger: File Logging Enabled = $($this.Config.fileLogEnabled)"
        Write-Host "phLogger: Console Logging Enabled = $($this.Config.consoleLogEnabled)"

        # Detect if LogPath is relative
        if (-not [System.IO.Path]::IsPathRooted($this.Config.LogPath)) {
            Write-Host "phLogger: Log Path is relative, converting to absolute path."
            $this.Config.LogPath = Join-Path $PSScriptRoot $this.Config.LogPath
            Write-Host "phLogger: Log Path is now '$($this.Config.LogPath)'"
        }

        # Trim log if oversized
        if (Test-Path $this.Config.LogPath) {
            $currentSize = (Get-Item $this.Config.LogPath).length / 1024
            if ($currentSize -gt $this.Config.MaxSizeKB) {
                Write-Host "phLogger: Log file exceeds max size of $($this.Config.MaxSizeKB)KB, trimming."
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
        $logLine = "$timestamp [$Level] $Message"

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
}