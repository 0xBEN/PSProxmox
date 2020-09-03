function Get-ProxmoxUsers {

    [CmdletBinding()]
    Param (
    )
    begin { if ($SkipProxmoxCertificateCheck) { Disable-CertificateValidation } }
    process {

        try {

            Invoke-RestMethod `
            -Method Get `
            -Uri ($proxmoxApiBaseUri.AbsoluteUri + 'access/users') `
            -WebSession $ProxmoxWebSession
            
        }
        catch {

            throw $_.Exception

        }

    }
    end { if ($SkipProxmoxCertificateCheck) { Enable-CertificateValidation } }

}