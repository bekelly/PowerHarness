$ErrorActionPreference = 'Stop'

class phUtil {

    #----------------------------------------------------------------------------------------------
    # MergeJSONObjects
    #
    # Merges two JSON objects (represented as PSCustomObjects) recursively.
    # The $Override object takes precedence over $Default.
    #----------------------------------------------------------------------------------------------
    [PSCustomObject] MergeJsonObjects([PSCustomObject]$Default, [PSCustomObject]$Override) {
        foreach ($prop in $Override.PSObject.Properties) {
            $name  = $prop.Name
            $value = $prop.Value

            if ($Default.PSObject.Properties.Name -contains $name) {
                # both are objects? recurse
                if ($value -is [PSCustomObject] -and
                    $Default.$name -is [PSCustomObject]) {
                    $Default.$name = $this.MergeJsonObjects($Default.$name, $value)
                }
                else {
                    # override scalar or array
                    $Default.PSObject.Properties[$name].Value = $value
                }
            }
            else {
                # brand-new property → add it
                $Default | Add-Member -MemberType NoteProperty -Name $name -Value $value
            }
        }
        return $Default
    }

    #----------------------------------------------------------------------------------------------
    # ArchiveFilesByDate
    #
    # Moves files and folders older than $daysOld from $sourceDirectory to $archiveDirectory.
    #----------------------------------------------------------------------------------------------
    [string] ArchiveFilesByDate ([string]$sourceDirectory, [string]$archiveDirectory, [int]$daysOld = 30) {
    
        # this is a quick-and-dirty function that Copilot wrote for me.  I'm *sure* it could be cleaner

        $cutoffDate = (Get-Date).AddDays(-$daysOld)

        function Get-UniqueName {
            param (
                [string]$baseName,
                [string]$targetPath
            )

            $name = [System.IO.Path]::GetFileNameWithoutExtension($baseName)
            $ext = [System.IO.Path]::GetExtension($baseName)
            $counter = 1

            $newName = $baseName
            while (Test-Path (Join-Path $targetPath $newName)) {
                $newName = "$name-$counter$ext"
                $counter++
            }

            return $newName
        }

        # --- Move files ---
        $filesToMove = Get-ChildItem -Path $sourceDirectory -File | Where-Object {
            $_.LastAccessTime -le $cutoffDate
        }

        $filesToMove | ForEach-Object {
            $targetPath = Join-Path $archiveDirectory $_.Name
            if (Test-Path $targetPath) {
                $uniqueName = Get-UniqueName $_.Name $archiveDirectory
                $targetPath = Join-Path $archiveDirectory $uniqueName
            }
            Move-Item -Path $_.FullName -Destination $targetPath
        }

        $fileListHtml = ($filesToMove | Select-Object -ExpandProperty Name) -join '<br>'
        if ([string]::IsNullOrWhiteSpace($fileListHtml)) {
            $fileListHtml = "(none)"
        }

        # --- Move folders ---
        $foldersToMove = Get-ChildItem -Path $sourceDirectory -Directory | Where-Object {
            $_.CreationTime -le $cutoffDate
        }

        $foldersToMove | ForEach-Object {
            $targetPath = Join-Path $archiveDirectory $_.Name
            if (Test-Path $targetPath) {
                $uniqueName = Get-UniqueName $_.Name $archiveDirectory
                $targetPath = Join-Path $archiveDirectory $uniqueName
            }
            Move-Item -Path $_.FullName -Destination $targetPath
        }

        $folderListHtml = ($foldersToMove | Select-Object -ExpandProperty Name) -join '<br>'
        if ([string]::IsNullOrWhiteSpace($folderListHtml)) {
            $folderListHtml = "(none)"
        }

        $finalOutput = "FILES:<br>$fileListHtml<br><br>FOLDERS:<br>$folderListHtml"
        return $finalOutput

    }

    #----------------------------------------------------------------------------------------------
    # Install-ModuleIfNeeded
    #
    # Moves files and folders older than $daysOld from $sourceDirectory to $archiveDirectory.
    #----------------------------------------------------------------------------------------------
    [void] InstallModuleIfNeeded ([string]$ModuleName, [string]$RequiredVersion) {

        if ($RequiredVersion) {
            # Check for exact version
            $installed = Get-Module -ListAvailable -Name $ModuleName |
                Where-Object { $_.Version -eq [version]$RequiredVersion }

            if (-not $installed) {
                Install-Module -Name $ModuleName -RequiredVersion $RequiredVersion -Scope CurrentUser -Force -Confirm:$false
            }
        } else {
            # Check if *any* version is installed
            $installed = Get-Module -ListAvailable -Name $ModuleName

            if (-not $installed) {
                Install-Module -Name $ModuleName -Scope CurrentUser -Force -Confirm:$false
            }
        }

    }

}