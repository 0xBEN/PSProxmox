function Get-ProxmoxNode {

    [CmdletBinding()]
    Param ()
    begin { 

        try { Confirm-ProxmoxApiConnection }
        catch { throw "Please connect to the Proxmox API using the command: Connect-ProxmoxApi" }

        if ($SkipProxmoxCertificateCheck) {            
            if ($PSVersionTable.PSEdition -ne 'Core') { Disable-CertificateValidation } # Custom function to bypass X.509 cert checks
            else { $NoCertCheckPSCore = $true }        
        }
        $uri = $proxmoxApiBaseUri.AbsoluteUri + 'nodes'

    }
    process {

        try {

            if ($NoCertCheckPSCore) {
                $node = Invoke-RestMethod `
                -Method Get `
                -Uri $uri `
                -SkipCertificateCheck `
                -WebSession $ProxmoxWebSession | Select-Object -ExpandProperty data
            }
            else {
                $node = Invoke-RestMethod `
                -Method Get `
                -Uri $uri `
                -WebSession $ProxmoxWebSession | Select-Object -ExpandProperty data    
            }
            
        }
        catch {

            throw $_.Exception

        }

    }
    end { 
        
        if ($SkipProxmoxCertificateCheck -and -not $NoCertCheckPSCore) { Enable-CertificateValidation } 
        if ($node) { 

            $node | ForEach-Object {

                $Node | ForEach-Object {

                    $ProxmoxNode = New-Object ProxmoxNode
                    $ProxmoxNode.node = $_.node
                    $ProxmoxNode.status = $_.status
                    $ProxmoxNode.cpu = $_.cpu
                    $ProxmoxNode.level = $_.level
                    $ProxmoxNode.maxcpu = $_.maxcpu
                    $ProxmoxNode.maxmem = $_.maxmem
                    $ProxmoxNode.mem = $_.mem
                    $ProxmoxNode.ssl_fingerprint = $_.ssl_fingerprint
                    $ProxmoxNode.uptime = $_.uptime
                    return $ProxmoxNode
                    
                }  

            }

        }
        else { return }
        
    }

}