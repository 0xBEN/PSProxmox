function Get-ProxmoxNodeApt {

    [CmdletBinding(DefaultParameterSetName = 'Versions')]
    Param (
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ParameterSetName = 'Changelog'
        )]
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ParameterSetName = 'Update'
        )]
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ParameterSetName = 'Versions'
        )]
        [PSObject[]]
        $ProxmoxNode,

        [Parameter(ParameterSetName = 'Changelog')]
        [Switch]
        $ChangeLog,

        [Parameter(
            ParameterSetName = 'Changelog',
            Mandatory = $true
        )]
        [ValidateNotNullOrEmpty()]
        [String]
        $PackageName,

        [Parameter(ParameterSetName = 'Changelog')]
        [ValidateNotNullOrEmpty()]
        [String]
        $Version,

        [Parameter(ParameterSetName = 'Update')]
        [Switch]
        $ListUpdates,

        [Parameter(ParameterSetName = 'Versions')]
        [Switch]
        $ListVersions
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

    }
    process {

        $ProxmoxNode | ForEach-Object {
            
            $node = $_
            if ($PSCmdlet.ParameterSetName -eq 'Changelog') {
                $body.Add('name', $PSBoundParameters['PackageName'])
                if ($PSBoundParameters['Version']) { $body.Add('version', $PSBoundParameters['Version']) }
                $uri = ($proxmoxApiBaseUri.AbsoluteUri + "nodes/$($node.node)/apt/changelog")
            }
            elseif ($PSCmdlet.ParameterSetName -eq 'Update') {
                $uri = ($proxmoxApiBaseUri.AbsoluteUri + "nodes/$($node.node)/apt/update")
            }
            else {
                $uri = ($proxmoxApiBaseUri.AbsoluteUri + "nodes/$($node.node)/apt/versions")
            }

            try {
                
                if ($NoCertCheckPSCore) { # PS Core client                    
                    Invoke-RestMethod `
                    -Method Get `
                    -Uri $uri `
                    -Body $body `
                    -SkipCertificateCheck `
                    -WebSession $ProxmoxWebSession | Select-Object -ExpandProperty data    
                }
                else { # PS Desktop client
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

    }
    end { if ($SkipProxmoxCertificateCheck -and -not $NoCertCheckPSCore) { Enable-CertificateValidation } }

}