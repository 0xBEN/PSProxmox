function Get-ProxmoxNodeVersion {

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String[]]
        $ProxmoxNodeName
    )
    begin { if ($SkipProxmoxCertificateCheck) { Disable-CertificateValidation } }
    process {

        $ProxmoxNodeName | ForEach-Object {
            
            try {

                Invoke-RestMethod `
                -Method Get `
                -Uri ($proxmoxApiBaseUri.AbsoluteUri + "nodes/$_/version") `
                -WebSession $ProxmoxWebSession | Select-Object -ExpandProperty data
                
            }
            catch {

                throw $_.Exception

            }

        }

    }
    end { if ($SkipProxmoxCertificateCheck) { Enable-CertificateValidation } }

}