function Get-ProxmoxUsers {

    [CmdletBinding()]
    Param (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String[]]
        $UserID
    )
    begin { if ($SkipProxmoxCertificateCheck) { Disable-CertificateValidation } }
    process {

        if ($UserID) {
            
            $UserID | ForEach-Object {

                try {

                    Invoke-RestMethod `
                    -Method Get `
                    -Uri ($proxmoxApiBaseUri.AbsoluteUri + "access/users/$_") `
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
                -Uri ($proxmoxApiBaseUri.AbsoluteUri + 'access/users') `
                -WebSession $ProxmoxWebSession | Select-Object -ExpandProperty data
                
            }
            catch {

                throw $_.Exception

            }

        }

    }
    end { if ($SkipProxmoxCertificateCheck) { Enable-CertificateValidation } }

}