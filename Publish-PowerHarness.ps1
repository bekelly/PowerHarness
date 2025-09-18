#--------------------------------------------------------------------------------------------------
# Publish-PowerHarness.ps1
#--------------------------------------------------------------------------------------------------
$ErrorActionPreference = 'Stop'

#--------------------------------------------------------------------------------------------------
# Retrieve package repository name from config file
#--------------------------------------------------------------------------------------------------
$cfgPath = Join-Path $PSScriptRoot "cfg\repository.txt"
if (-not (Test-Path $cfgPath)) {
    throw "Repository config file not found: $cfgPath"
}
$repositoryName = Get-Content $cfgPath | Select-Object -First 1
Write-Output "Using repository: $repositoryName"

#--------------------------------------------------------------------------------------------------
# Path to your module root
#--------------------------------------------------------------------------------------------------
$modulePath = Join-Path $PSScriptRoot "PowerHarness"
$manifestPath = Join-Path $modulePath "PowerHarness.psd1"
Write-Output "Module path: $manifestPath"

#--------------------------------------------------------------------------------------------------
# Load current X.Y version from manifest
#--------------------------------------------------------------------------------------------------
$manifest = Test-ModuleManifest $manifestPath
Write-Output "Current module version: $($manifest.Version)"
# $versionParts = $manifest.Version -split '\.'
$major = (Get-Date -Format "yy")
$minor = (Get-Date).Month

#--------------------------------------------------------------------------------------------------
# this is something that Copilot started me on, but I just like the commit counts, thankyouverymuch
#--------------------------------------------------------------------------------------------------
# # Get latest tag matching vX.Y.*
# $tagPattern = "v$major.$minor.*"
# $latestTag = git tag --list $tagPattern | Sort-Object { [version]($_ -replace '^v') } | Select-Object -Last 1

# # Count commits since latest tag
# $commitDelta = if ($latestTag) {
#     git rev-list $latestTag..HEAD --count
# } else {
#     git rev-list HEAD --count
# }

#--------------------------------------------------------------------------------------------------
# For simplicity, just use total commit count as patch version
#--------------------------------------------------------------------------------------------------
$commitDelta = git rev-list HEAD --count

#--------------------------------------------------------------------------------------------------
# Build new version string
#--------------------------------------------------------------------------------------------------
$newVersion = "$major.$minor.$commitDelta"

#--------------------------------------------------------------------------------------------------
# Update manifest
#--------------------------------------------------------------------------------------------------
(Get-Content $manifestPath) |
ForEach-Object {
    $_ -replace "ModuleVersion\s*=\s*'.*'", "ModuleVersion = '$newVersion'"
} | Set-Content $manifestPath

Write-Output "Updated manifest to version $newVersion"

#--------------------------------------------------------------------------------------------------
# Publish to BayshorePackages
#--------------------------------------------------------------------------------------------------
Publish-Module -Path $modulePath -Repository $repositoryName -Force
Write-Output "Published PowerHarness $newVersion to $repositoryName"

#--------------------------------------------------------------------------------------------------
# Commit and tag the new version
#--------------------------------------------------------------------------------------------------
# Stage the updated manifest
git add $manifestPath

# Commit the change
$commitMessage = "Publish PowerHarness v$newVersion"
git commit -m $commitMessage

# Create a version tag
$tagName = "v$newVersion"
git tag $tagName

# Push commit and tag to origin
git push origin HEAD
git push origin $tagName

Write-Output "Tagged commit as $tagName and pushed to origin"