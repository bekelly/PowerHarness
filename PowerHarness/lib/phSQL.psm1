using module '.\phLogger.psm1'
$ErrorActionPreference = 'Stop'

class phSQL {
    [PSCustomObject]$Config
    [phLogger]$Logger

    phSQL([PSCustomObject]$config, [phLogger]$logger){
        $this.Config = $config
        $this.Logger = $logger
    }
}