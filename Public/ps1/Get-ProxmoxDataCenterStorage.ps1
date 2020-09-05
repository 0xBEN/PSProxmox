function Get-ProxmoxDataCenterStorage {

    [CmdletBinding(DefaultParameterSetName = 'All')]
    Param (
        [Parameter(ParameterSetName = 'All')]
        [Switch]
        $All,
        
        [Parameter(ParameterSetName = 'Type')]
        [ValidateSet('cephfs', 'cifs', 'dir', 'drbd', 'glusterfs', 'iscsi', 'iscsidirect', 'lvm', 'lvmthin', 'nfs', 'pbs', 'rbd', 'zfs', 'zfspool')]
        [String]
        $Type,

        [Parameter(ParameterSetName = 'Name')]
        [String]
        $StorageId
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
        $body = @{}
        if ($PSBoundParameters['Type']) { $body.Add('type', $PSBoundParameters['Type']) }
        $uri = $proxmoxApiBaseUri.AbsoluteUri + 'storage'
            

    }
    process {

        if ($StorageId) {

            $StorageId | ForEach-Object {

                $uri = $uri + '/' + $_
                try {

                    if ($NoCertCheckPSCore) {
                        Invoke-RestMethod `
                        -Method Get `
                        -Uri $uri `
                        -SkipCertificateCheck `
                        -WebSession $ProxmoxWebSession | Select-Object -ExpandProperty data
                    }
                    else {
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
        else {

            try {

                if ($NoCertCheckPSCore) {
                    Invoke-RestMethod `
                    -Method Get `
                    -Uri ($proxmoxApiBaseUri.AbsoluteUri + 'storage') `
                    -Body $body `
                    -SkipCertificateCheck `
                    -WebSession $ProxmoxWebSession | Select-Object -ExpandProperty data
                }
                else {
                    Invoke-RestMethod `
                    -Method Get `
                    -Uri ($proxmoxApiBaseUri.AbsoluteUri + 'storage') `
                    -Body $body `
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