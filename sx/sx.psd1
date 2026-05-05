@{
    RootModule        = 'sx.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = 'b5e7c2a4-1f3d-4a7e-9f12-7c8d5b3a9e01'
    Author            = 'Johan Bjarnle'
    Description       = 'Saved SSH sessions for Windows Terminal + PowerShell.'
    PowerShellVersion = '5.1'
    RequiredModules   = @('powershell-yaml')
    FunctionsToExport = @('sx', 'sxp')
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
}
