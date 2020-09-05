function Get-ProxmoxNodeService {

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
        [ValidateSet('corosync', 'cron', 'ksmtuned', 'postfix', 'pve-cluster', 'pvedaemon', 'pve-firewall', 'pvefw-logger', 'pve-ha-crm', 'pve-ha-lrm', 'pveproxy', 'pvestatd', 'spiceproxy', 'sshd', 'syslog', 'systemd-timesyncd')]
        [String[]]
        $ServiceName
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
            if ($ServiceName) {

                $ServiceName | ForEach-Object {

                    try {
                    
                        if ($NoCertCheckPSCore) { # PS Core client                    
                            Invoke-RestMethod `
                            -Method Get `
                            -Uri ($proxmoxApiBaseUri.AbsoluteUri + "nodes/$($node.node)/services/$_/state") `
                            -SkipCertificateCheck `
                            -WebSession $ProxmoxWebSession | Select-Object -ExpandProperty data    
                        }
                        else { # PS Desktop client
                            Invoke-RestMethod `
                            -Method Get `
                            -Uri ($proxmoxApiBaseUri.AbsoluteUri + "nodes/$($node.node)/services/$_/state") `
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
                
                    if ($NoCertCheckPSCore) { # PS Core client                    
                        Invoke-RestMethod `
                        -Method Get `
                        -Uri ($proxmoxApiBaseUri.AbsoluteUri + "nodes/$($node.node)/services") `
                        -SkipCertificateCheck `
                        -WebSession $ProxmoxWebSession | Select-Object -ExpandProperty data    
                    }
                    else { # PS Desktop client
                        Invoke-RestMethod `
                        -Method Get `
                        -Uri ($proxmoxApiBaseUri.AbsoluteUri + "nodes/$($node.node)/services") `
                        -WebSession $ProxmoxWebSession | Select-Object -ExpandProperty data
                    }
                    
                }
                catch {
    
                    throw $_.Exception
    
                }

            }

        }

    }
    end { if ($SkipProxmoxCertificateCheck -and -not $NoCertCheckPSCore) { Enable-CertificateValidation } }

}