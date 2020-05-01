function Enable-CertificateValidation {

    [CmdletBinding()]
    Param(

    )
    process {

        if (([System.Management.Automation.PSTypeName]"TrustEverything").Type) { [TrustEverything]::UnsetCallback() }
    
    }

}