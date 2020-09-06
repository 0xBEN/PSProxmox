function Get-ProxmoxNodeSyslog {

    [CmdletBinding()]
    Param (
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true
        )]
        [ProxmoxNode[]]
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

        try { Confirm-ProxmoxApiConnection }
        catch { throw "Please connect to the Proxmox API using the command: Connect-ProxmoxApi" }

        if ($SkipProxmoxCertificateCheck) {            
            if ($PSVersionTable.PSEdition -ne 'Core') { Disable-CertificateValidation } # Custom function to bypass X.509 cert checks
            else { $NoCertCheckPSCore = $true }        
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
            
            $uri = $proxmoxApiBaseUri.AbsoluteUri + "nodes/$($_.node)/syslog"
            try {
                
                if ($NoCertCheckPSCore) { # PS Core client                    
                    Invoke-RestMethod `
                    -Method Get `
                    -Uri $uri `
                    -SkipCertificateCheck `
                    -Body $body `
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