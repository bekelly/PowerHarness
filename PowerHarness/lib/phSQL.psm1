using module '.\phLogger.psm1'
$ErrorActionPreference = 'Stop'

class phSQL {
    [phLogger]       $Logger
    [PSCustomObject] $Config
    [PSCustomObject] $ConnectionParams

    phSQL([PSCustomObject]$config, [phLogger]$logger){
        $this.Config = $config
        $this.Logger = $logger
    }

    [void] SetConnection([PSCustomObject]$connectionParams){
        $this.ConnectionParams = $connectionParams
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

    [void] ExecNonQuery([string]$sqlCommand, [hashtable]$parameters) {

        $connectionString = "Server={0};Database={1};User Id={2};Password={3}" -f `
            $this.ConnectionParams.server, `
            $this.ConnectionParams.database, `
            $this.ConnectionParams.username, `
            $this.ConnectionParams.password

        $connection = $null

        $this.DebugLog("Running ExecNoQuery")

        try {
            $connection = New-Object System.Data.SqlClient.SqlConnection
            $connection.ConnectionString = $connectionString
            $this.DebugLog("Opening database connection to $($this.ConnectionParams.database) on $($this.ConnectionParams.server)")
            $connection.Open()

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

        $connectionString = "Server={0};Database={1};User Id={2};Password={3}" -f `
            $this.ConnectionParams.server, `
            $this.ConnectionParams.database, `
            $this.ConnectionParams.username, `
            $this.ConnectionParams.password
        $connection = $null
        $dataTable = $null

        try {
            $connection = New-Object System.Data.SqlClient.SqlConnection
            $connection.ConnectionString = $connectionString
            $connection.Open()

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