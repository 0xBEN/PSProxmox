function Read-SecureString {
    
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            Position = 0
        )]
        [System.Security.SecureString[]]
        $SecureString
    )
    process {

        $SecureString | ForEach-Object {
            try {
                [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR(($_)))
            }
            catch {
                Write-Error -Exception $_.Exception
            }
        }

    }
    
}