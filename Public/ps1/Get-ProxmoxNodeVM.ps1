function Get-ProxmoxNodeVM {

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $ProxmoxNodeName,

        [Parameter()]
        [Int[]]
        $VMID
    )
    begin { if ($SkipProxmoxCertificateCheck) { Disable-CertificateValidation } }
    process {

        if ($VMID) {

            $VMID | ForEach-Object {
                
                try {

                    Invoke-RestMethod `
                    -Method Get `
                    -Uri ($proxmoxApiBaseUri.AbsoluteUri + "nodes/$ProxmoxNodeName/qemu/$_/status/current") `
                    -WebSession $ProxmoxWebSession | Select-Object -ExpandProperty data
                    
                }
                catch {
    
                    Write-Error -Exception $_.Exception
    
                }    

            }

        }
        else {

            try {

                Invoke-RestMethod `
                -Method Get `
                -Uri ($proxmoxApiBaseUri.AbsoluteUri + "nodes/$ProxmoxNodeName/qemu") `
                -WebSession $ProxmoxWebSession | Select-Object -ExpandProperty data
                
            }
            catch {

                throw $_.Exception

            }

        }

    }
    end { if ($SkipProxmoxCertificateCheck) { Enable-CertificateValidation } }

}