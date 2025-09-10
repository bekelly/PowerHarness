using module '.\phLogger.psm1'
$ErrorActionPreference = 'Stop'

class phSQL {
    [phLogger]       $Logger
    [PSCustomObject] $ConnectionParams

    phSQL([phLogger]$logger){
        $this.Logger = $logger
    }

    [void] SetConnection([PSCustomObject]$connectionParams){
        $this.ConnectionParams = $connectionParams
    }

    [void] ExecNonQuery([string]$sqlCommand) {
        $connectionString = "Server={0};Database={1};User Id={2};Password={3}" -f `
            $this.ConnectionParams.server, `
            $this.ConnectionParams.database, `
            $this.ConnectionParams.username, `
            $this.ConnectionParams.password

        $connection = $null

        try {
            $connection = New-Object System.Data.SqlClient.SqlConnection
            $connection.ConnectionString = $connectionString
            $connection.Open()

            $command = $connection.CreateCommand()
            $command.CommandText = $sqlCommand
            $rowsAffected = $command.ExecuteNonQuery()

            $this.Logger.Info("SQL ExecNonQuery completed. Rows affected: $rowsAffected")
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