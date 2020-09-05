function Get-ProxmoxDataCenterPerformance {

    [CmdletBinding()]
    Param (
        [Parameter()]
        [ValidateSet('node', 'sdn', 'storage', 'vm')]
        [String]
        $Type
    )
    begin { 

        if ($SkipProxmoxCertificateCheck) {
            
            if ($PSVersionTable.PSEdition -ne 'Core') {
                Disable-CertificateValidation # Custom function to bypass X.509 cert checks
            }
            else {
                $NoCertCheckPSCore = $true
            }
        
        }
        $uri = $proxmoxApiBaseUri.AbsoluteUri + 'cluster/resources'
        $body = @{}
        if ($PSBoundParameters['Type']) { $body.Add('type', $PSBoundParameters['Type']) }

    }
    process {

        try {

            if ($NoCertCheckPSCore) {
                Invoke-RestMethod `
                -Method Get `
                -Uri $uri `
                -Body $body `
                -SkipCertificateCheck `
                -WebSession $ProxmoxWebSession | Select-Object -ExpandProperty data
            }
            else {
                Invoke-RestMethod `
                -Method Get `
                -Uri $uri `
                -Body $body `
                -WebSession $ProxmoxWebSession | Select-Object -ExpandProperty data    
            }
            
        }
        catch {

            throw $_.Exception

        }

    }
    end { if ($SkipProxmoxCertificateCheck -and -not $NoCertCheckPSCore) { Enable-CertificateValidation } }

}