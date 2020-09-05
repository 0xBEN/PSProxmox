function Get-ProxmoxNodeSyslog {

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
        [Int]
        $ResultCount,

        [Parameter()]
        [Int]
        $StartAtLogLine,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]
        $ServiceID,

        [Parameter()]
        [DateTime]
        $StartDate,

        [Parameter()]
        [DateTime]
        $EndDate
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
        if ($PSBoundParameters['ResultCount']) { $body.Add('limit', $PSBoundParameters['ResultCount']) }
        if ($PSBoundParameters['StartAtLogLine']) { $body.Add('start', $PSBoundParameters['StartAtLogLine']) }
        if ($PSBoundParameters['ServiceID']) { $body.Add('service', $PSBoundParameters['ServiceID']) }
        if ($PSBoundParameters['StartDate']) { $body.Add('since', $PSBoundParameters['StartDate'].ToString('yyyy-MM-dd hh:mm:ss')) }
        if ($PSBoundParameters['EndDate']) { $body.Add('until', $PSBoundParameters['EndDate'].ToString('yyyy-MM-dd hh:mm:ss')) }

    }
    process {

        $ProxmoxNode | ForEach-Object {
            
            $node = $_
            try {
                
                if ($NoCertCheckPSCore) { # PS Core client                    
                    Invoke-RestMethod `
                    -Method Get `
                    -Uri ($proxmoxApiBaseUri.AbsoluteUri + "nodes/$($node.node)/syslog") `
                    -SkipCertificateCheck `
                    -Body $body `
                    -WebSession $ProxmoxWebSession | Select-Object -ExpandProperty data    
                }
                else { # PS Desktop client
                    Invoke-RestMethod `
                    -Method Get `
                    -Uri ($proxmoxApiBaseUri.AbsoluteUri + "nodes/$($node.node)/syslog") `
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