using module '.\phLogger.psm1'
using module '.\phUtil.psm1'
$ErrorActionPreference = 'Stop'

class phSQL {
    [phLogger]       $Logger
    [phUtil]         $Util
    [PSCustomObject] $Config
    [PSCustomObject] $ConnectionParams

    #----------------------------------------------------------------------------------------------
    # constructor
    #----------------------------------------------------------------------------------------------
    phSQL([PSCustomObject]$config, [phLogger]$logger, [phUtil]$util) {
        $this.Config = $config
        $this.Logger = $logger
        $this.Util = $util
    }

    #----------------------------------------------------------------------------------------------
    # SetConnection
    #----------------------------------------------------------------------------------------------
    [void] SetConnection([PSCustomObject]$connectionParams) {

        #------------------------------------------------------------------------------------------
        # set default values on the connection so we can use them everywhere
        #------------------------------------------------------------------------------------------
        $this.Logger.Debug("Entered SetConnection")
        $this.Util.EnsureDefaults($connectionParams, @{
                connectionRetries = 3
                sleepSeconds      = 5
            })

        #------------------------------------------------------------------------------------------
        # make this our current connection
        #------------------------------------------------------------------------------------------
        $this.ConnectionParams = $connectionParams

        #------------------------------------------------------------------------------------------
        # log the parameters
        #------------------------------------------------------------------------------------------
        $this.DebugLog("SetConnection:")
        $this.DebugLog("Server Name: $($this.ConnectionParams.server)")
        $this.DebugLog("   Database: $($this.ConnectionParams.database)")
        $this.DebugLog("   Username: $($this.ConnectionParams.username)")
        $masked = '*' * ($this.ConnectionParams.password.Length)
        $this.DebugLog("   Password: $masked")

    }

    hidden [void] DebugLog([string]$message) {
        if ($this.Config.debugLogEnabled) {
            $this.Logger.Debug("SQL > $message")
        }
    }

    [void] ExecNonQuery([string]$sqlCommand) {
        $this.ExecNonQuery($sqlCommand, @{})
    }

    hidden [System.Data.SqlClient.SqlConnection] ConnectWithRetry() {

        $connectionString = "Server={0};Database={1};User Id={2};Password={3}" -f `
            $this.ConnectionParams.server, `
            $this.ConnectionParams.database, `
            $this.ConnectionParams.username, `
            $this.ConnectionParams.password

        $connection = New-Object System.Data.SqlClient.SqlConnection

        $connection.ConnectionString = $connectionString

        for ($i = 1; $i -le $this.ConnectionParams.connectionRetries; $i++) {
            try {
                $this.DebugLog("Attempt ${i}: Opening database connection to $($connection.Database) on $($connection.DataSource)")
                $connection.Open()
                return $connection
            }
            catch {
                $this.DebugLog("SQL connection attempt $i failed: $_")
                if ($i -lt $this.ConnectionParams.connectionRetries) {
                    Start-Sleep -Seconds $this.ConnectionParams.sleepSeconds
                }
                else {
                    throw "SQL connection failed after $($this.ConnectionParams.connectionRetries) attempts."
                }
            }
        }

        return null
    }

    [void] ExecNonQuery([string]$sqlCommand, [hashtable]$parameters) {

        $this.DebugLog("Running ExecNoQuery")
        $connection = $null

        try {
            $this.DebugLog("Opening database connection to $($this.ConnectionParams.database) on $($this.ConnectionParams.server)")
            $connection = $this.ConnectWithRetry()

            $command = $connection.CreateCommand()
            $command.CommandText = $sqlCommand

            foreach ($key in $parameters.Keys) {
                $param = $command.Parameters.Add("@$key", [System.Data.SqlDbType]::VarChar)
                $param.Value = $parameters[$key]
            }

            $this.DebugLog("Executing command: $sqlCommand")
            $rowsAffected = $command.ExecuteNonQuery()

            $this.DebugLog("SQL ExecNonQuery completed. Rows affected: $rowsAffected")
        }
        catch {
            $this.Logger.Error("SQL ExecNonQuery error: $_")
            throw
        }
        finally {
            if ($connection -and $connection.State -eq 'Open') {
                $connection.Close()
            }
        }
    }

    [System.Data.DataTable] ExecReaderToDataTable([string]$sqlCommand) {

        $connection = $null
        $dataTable = $null

        try {
            $connection = $this.ConnectWithRetry()

            # Running the query
            $command = $connection.CreateCommand()
            $command.CommandText = $sqlCommand
            $reader = $command.ExecuteReader()

            # Storing the results in a DataTable
            $dataTable = New-Object System.Data.DataTable
            $dataTable.Load($reader)
        }
        catch {
            $this.Logger.Error("SQL ExecReader error: $_")
            throw
        }
        finally {
            if ($connection -and $connection.State -eq 'Open') {
                $connection.Close()
            }
        }
        return $dataTable
    }

    [string] ConvertDataTableToHtmlTable([System.Data.DataTable]$DataTable) {
        $html = "<table class='sqltable' border='1' cellpadding='3' cellspacing='0' style='font-size: 9pt; font-family: Aptos, Arial, sans-serif;'>"
        # Add table headers
        $html += "<thead><tr>"
        foreach ($column in $DataTable.Columns) {
            $html += "<th class='sqlhead'>$($column.ColumnName)</th>"
        }
        $html += "</tr></thead>"

        # Add table rows
        $html += "<tbody class='sqlbody'>"
        foreach ($row in $DataTable.Rows) {
            $html += "<tr class='sqlrow'>"
            foreach ($column in $DataTable.Columns) {
                $html += "<td class='sqlcell'>$($row[$column.ColumnName])</td>"
            }
            $html += "</tr>"
        }
        $html += "</tbody></table>"

        return $html
    }

    [string] ExecReaderToHtmlTable([string]$sqlCommand) {
        $dataTable = $this.ExecReaderToDataTable($sqlCommand)
        return $this.ConvertDataTableToHtmlTable($dataTable)
    }
}