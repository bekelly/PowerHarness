@{
    # Core module info
    RootModule        = 'PowerHarness.psm1'
    ModuleVersion = '0.9.28'
    GUID              = 'd3c1a9e2-1234-4b56-89ab-abcdef123456'
    Author            = 'Brian Kelly'
    CompanyName       = 'Bayshore Records'
    Description       = 'A modular PowerShell harness for testing, logging, and automation workflows.'

    # Compatibility
    PowerShellVersion = '5.1'
    CompatiblePSEditions = @('Desktop', 'Core')

    # Exported members
    FunctionsToExport = @('Get-PowerHarness')
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()

    # Nested modules (if you use lib/*.psm1 files)
    NestedModules     = @(
        'lib\phUtil.psm1',
        'lib\phLogger.psm1',
        'lib\phEmailer.psm1',
        'lib\phSQL.psm1'
    )

    # Optional: dependencies
    RequiredModules   = @()

    # Optional: help and licensing
    HelpInfoUri       = ''

    # Private data for gallery publishing
    PrivateData = @{
        PSData = @{
            Tags         = @('logging','testing','automation','PowerHarness')
            ReleaseNotes = 'Initial release of PowerHarness module.'
            LicenseUri        = 'https://opensource.org/licenses/MIT'
            ProjectUri        = 'https://github.com/bekelly/PowerHarness'
        }
    }
}
