function Get-ProxmoxNodeHardware {

    [CmdletBinding()]
    Param (
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true
        )]
        [PSObject[]]
        $ProxmoxNode,

        [Parameter()]
        [ValidateSet('pci')]
        [String]
        $Type = 'pci'
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

    }
    process {

        $ProxmoxNode | ForEach-Object {
            
            $node = $_
            $uri = ($proxmoxApiBaseUri.AbsoluteUri + "nodes/$($node.node)/hardware/$Type")
            try {
                
                if ($NoCertCheckPSCore) { # PS Core client                    
                    Invoke-RestMethod `
                    -Method Get `
                    -Uri $uri `
                    -SkipCertificateCheck `
                    -WebSession $ProxmoxWebSession | Select-Object -ExpandProperty data    
                }
                else { # PS Desktop client
                    Invoke-RestMethod `
                    -Method Get `
                    -Uri $uri `
                    -WebSession $ProxmoxWebSession | Select-Object -ExpandProperty data
                }
                
            }
            catch {

                throw $_.Exception

            }

        }

    }
    end { if ($SkipProxmoxCertificateCheck -and -not $NoCertCheckPSCore) { Enable-CertificateValidation } }

}