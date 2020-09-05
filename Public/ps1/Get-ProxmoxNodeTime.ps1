function Get-ProxmoxNodeTime {

    [CmdletBinding()]
    Param (
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true
        )]
        [PSObject[]]
        $ProxmoxNode
    )
    begin { 

        try { Confirm-ProxmoxApiConnection }
        catch { throw "Please connect to the Proxmox API using the command: Connect-ProxmoxApi" }

        if ($SkipProxmoxCertificateCheck) {            
            if ($PSVersionTable.PSEdition -ne 'Core') { Disable-CertificateValidation } # Custom function to bypass X.509 cert checks
            else { $NoCertCheckPSCore = $true }        
        }
        
        [DateTime]$epoch = '1970-01-01 00:00:00'

    }
    process {

        $ProxmoxNode | ForEach-Object {

            $uri = $proxmoxApiBaseUri.AbsoluteUri + "nodes/$($_.node)/time"
            try {

                if ($NoCertCheckPSCore) {
                    $data = Invoke-RestMethod `
                    -Method Get `
                    -Uri $uri `
                    -SkipCertificateCheck `
                    -WebSession $ProxmoxWebSession | Select-Object -ExpandProperty data
                    $data.time = $epoch.AddSeconds($data.time)
                    $data.localtime = $epoch.AddSeconds($data.localtime)
                    return $data    
                }
                else {
                    $data = Invoke-RestMethod `
                    -Method Get `
                    -Uri $uri `
                    -WebSession $ProxmoxWebSession | Select-Object -ExpandProperty data
                    $data.time = $epoch.AddSeconds($data.time)
                    $data.localtime = $epoch.AddSeconds($data.localtime)
                    return $data    
                }
                
            }
            catch {

                throw $_.Exception

            }

        }

    }
    end { if ($SkipProxmoxCertificateCheck -and -not $NoCertCheckPSCore) { Enable-CertificateValidation } }

}