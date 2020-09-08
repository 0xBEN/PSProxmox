function Get-PVENodeVMOSInfo {

    [CmdletBinding()]
    Param (
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true
        )]
        [ProxmoxNode[]]
        $ProxmoxNode,

        [Parameter(
            Mandatory = $true,
            Position = 1
        )]
        [String[]]
        $VMID
    )
    begin { 

        try { Confirm-PveApiConnection }
        catch { throw "Please connect to the Proxmox API using the command: Connect-ProxmoxApi" }

        if ($SkipProxmoxCertificateCheck) {            
            if ($PSVersionTable.PSEdition -ne 'Core') { Disable-CertificateValidation } # Custom function to bypass X.509 cert checks
            else { $NoCertCheckPSCore = $true }        
        }

    }
    process {

        $ProxmoxNode | ForEach-Object {
            
            $uri = $proxmoxApiBaseUri.AbsoluteUri + "nodes/$($_.node)/qemu/"
            $VMID | ForEach-Object {

                $uri = $uri + $_ + '/agent/get-osinfo'
                try {
                    
                    if ($NoCertCheckPSCore) { # PS Core client                    
                        Invoke-RestMethod `
                        -Method Get `
                        -Uri $uri `
                        -SkipCertificateCheck `
                        -WebSession $ProxmoxWebSession | 
                            Select-Object -ExpandProperty data | 
                            Select-Object -ExpandProperty result   
                    }
                    else { # PS Desktop client
                        Invoke-RestMethod `
                        -Method Get `
                        -Uri $uri `
                        -WebSession $ProxmoxWebSession | 
                            Select-Object -ExpandProperty data | 
                            Select-Object -ExpandProperty result
                    }
                    
                }
                catch {

                    if ($_.Exception.Response.StatusDescription -eq 'QEMU guest agent is not running') {
                        throw 'QEMU guest agent is not running'
                    }
                    else {
                        throw $_.Exception
                    }

                }

            }

        }

    }
    end { if ($SkipProxmoxCertificateCheck -and -not $NoCertCheckPSCore) { Enable-CertificateValidation } }

}
