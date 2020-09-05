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
        if ($SkipProxmoxCertificateCheck) {
            
            if ($PSVersionTable.PSEdition -ne 'Core') {
                Disable-CertificateValidation # Custom function to bypass X.509 cert checks
            }
            else {
                $NoCertCheckPSCore = $true
            }
        
        }
        [DateTime]$epoch = '1970-01-01 00:00:00'
    }
    process {

        $ProxmoxNode | ForEach-Object {

            $node = $_
            try {

                if ($NoCertCheckPSCore) {
                    $data = Invoke-RestMethod `
                    -Method Get `
                    -Uri ($proxmoxApiBaseUri.AbsoluteUri + "nodes/$($node.node)/time") `
                    -SkipCertificateCheck `
                    -WebSession $ProxmoxWebSession | Select-Object -ExpandProperty data
                    $data.time = $epoch.AddSeconds($data.time)
                    $data.localtime = $epoch.AddSeconds($data.localtime)
                    return $data    
                }
                else {
                    $data = Invoke-RestMethod `
                    -Method Get `
                    -Uri ($proxmoxApiBaseUri.AbsoluteUri + "nodes/$($node.node)/time") `
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