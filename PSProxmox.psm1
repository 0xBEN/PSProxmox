$publicFunctions = Get-ChildItem -Path "$PSScriptRoot\Public\ps1"
$privateFunctions = Get-ChildItem -Path "$PSScriptRoot\Private\ps1"
$moduleManifest = "$PSScriptRoot\PSProxmox.psd1"
$publicFunctions | ForEach-Object { . $_.FullName }
$privateFunctions | ForEach-Object { . $_.FullName }

$aliases = @()
$publicFunctions | ForEach-Object { # Export all of the public functions from this module
    
    $hasAlias = Get-Content $_.FullName | Select-String "\[alias" # Check if any of the functions have aliases set eg. [alias("shortcut", "scut")] by reading the text of the script file
    if ($hasAlias) { # If alias string found (see example above)

        $filter = $hasAlias.Line.Split('"*",') -replace "\[\w+\(", "" -replace "\)\]", "" # Split the string where there is a pattern of '"string",' -- creating an array -- then replace the [alias()] characters with whitespace
        $alias = $filter | Where-Object { -not[string]::IsNullOrWhiteSpace($_) } # Remove any whitespace from the string, leaving only characters
        $aliases += $alias
        Export-ModuleMember -Function $_.BaseName -Alias $alias

    }
    else {

        Export-ModuleMember -Function $_.BaseName

    }

}

if (-not $aliases) { $aliases = "*" }
try {
    Update-ModuleManifest -Path $moduleManifest -FunctionsToExport $publicFunctions.BaseName -AliasesToExport $aliases
}
catch {
    Out-Null
}
