function Get-ProxmoxNode {

    [CmdletBinding()]
    Param (
        [Parameter(ParameterSetName = 'Name')]
        [ValidateNotNullOrEmpty()]
        [String[]]
        $NodeName
    )
    begin { if ($SkipProxmoxCertificateCheck) { Disable-CertificateValidation } }
    process {

        if ($NodeName) {

            $NodeName | ForEach-Object {

                try {

                    Invoke-RestMethod `
                    -Method Get `
                    -Uri ($proxmoxApiBaseUri.AbsoluteUri + "nodes/$_") `
                    -WebSession $ProxmoxWebSession | Select-Object -ExpandProperty data
                    
                }
                catch {

                    throw $_.Exception
        
                }
        
            }
            
        }
        else {
            
            try {

                Invoke-RestMethod `
                -Method Get `
                -Uri ($proxmoxApiBaseUri.AbsoluteUri + 'nodes') `
                -WebSession $ProxmoxWebSession | Select-Object -ExpandProperty data
                
            }
            catch {

                throw $_.Exception

            }

        }

    }
    end { if ($SkipProxmoxCertificateCheck) { Enable-CertificateValidation } }

}