function Get-ProxmoxVM {

    [CmdletBinding(DefaultParameterSetName = 'All')]
    Param (
        [Parameter(Mandatory = $true, ParameterSetName = 'All')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ID')]
        [ValidateNotNullOrEmpty()]
        [String]
        $ProxmoxNodeName,

        [Parameter(ParameterSetName = 'All')]
        [Switch]
        $All,

        [Parameter(Mandatory = $true, ParameterSetName = 'ID')]
        [Int[]]
        $VMID
    )
    begin { if ($SkipProxmoxCertificateCheck) { Disable-CertificateValidation } }
    process {

        if ($PSCmdlet.ParameterSetName -eq 'All') {

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
        else {

            $VMID | ForEach-Object {
                
                $id = $_
                try {

                    Invoke-RestMethod `
                    -Method Get `
                    -Uri ($proxmoxApiBaseUri.AbsoluteUri + "nodes/$ProxmoxNodeName/qemu/$id/status/current") `
                    -WebSession $ProxmoxWebSession | Select-Object -ExpandProperty data
                    
                }
                catch {
    
                    Write-Error -Exception $_.Exception
    
                }    

            }

        }

    }
    end { if ($SkipProxmoxCertificateCheck) { Enable-CertificateValidation } }

}