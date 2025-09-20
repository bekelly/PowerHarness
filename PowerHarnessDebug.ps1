param (
    [string]$ScriptToRun
)

Write-Host "Debug Harness Launching script: $ScriptToRun" -ForegroundColor White -BackgroundColor DarkGreen

$command = "& '$ScriptToRun'; Write-Host 'Press any key to exit...'; [void][System.Console]::ReadKey()"
Start-Process powershell -ArgumentList "-Command", $command