$publicFunctions = Get-ChildItem -Path "$PSScriptRoot\Public\ps1"
$privateFunctions = Get-ChildItem -Path "$PSScriptRoot\Private\ps1"
$classes = Get-ChildItem -Path "$PSScriptRoot\Classes\ps1"
$publicFunctions | ForEach-Object { . $_.FullName }
$privateFunctions | ForEach-Object { . $_.FullName }
$classes | ForEach-Object { . $_.FullName }

$aliases = @()
$publicFunctions | ForEach-Object { # Export all of the public functions from this module
    
    $hasAlias = Get-Content $_.FullName | Select-String "\[alias" # Check if any of the functions have aliases set eg. [alias("shortcut", "scut")] by reading the text of the script file
    if ($hasAlias) { # If alias string found (see example above)
        $alias = $hasAlias.Line -split '"' -replace '\[Alias\(' -replace '\W' | Where-Object { -not [string]::IsNullOrEmpty($_) }
        $aliases += $alias
        Export-ModuleMember -Function $_.BaseName -Alias $alias
    }
    else {
        Export-ModuleMember -Function $_.BaseName        
    }

}

$moduleName = $PSScriptRoot.Split([System.IO.Path]::DirectorySeparatorChar)[-1]
$moduleManifest = "$PSScriptRoot\$moduleName.psd1"
$currentManifest = powershell -NoProfile -Command "Test-ModuleManifest '$moduleManifest' | ConvertTo-Json" | ConvertFrom-Json # Unfortunate hack to test the module manifest for changes without having to reload PowerShell
$functionsAdded = $publicFunctions | Where-Object {$_.BaseName -notin $currentManifest.ExportedFunctions.PSObject.Properties.Name}
$functionsRemoved = $currentManifest.ExportedFunctions.PSObject.Properties.Name | Where-Object {$_ -notin $publicFunctions.BaseName}
$aliasesAdded = $aliases | Where-Object {$_ -notin $currentManifest.ExportedAliases.PSObject.Properties.Name}
$aliasesRemoved = $currentManifest.ExportedAliases.PSObject.Properties.Name | Where-Object {$_ -notin $aliases}
if ($functionsAdded -or $functionsRemoved -or $aliasesAdded -or $aliasesRemoved) { 
    try {
        Update-ModuleManifest -Path "$PSScriptRoot\$moduleName.psd1" -FunctionsToExport $publicFunctions.BaseName -AliasesToExport $aliases -ErrorAction Stop 
    }
    catch {
        # Empty to silence errors
    }
}