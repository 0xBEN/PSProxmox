function Get-ProxmoxNodeTime {

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String[]]
        $ProxmoxNodeName
    )
    begin { 
        if ($SkipProxmoxCertificateCheck) { Disable-CertificateValidation }
        [DateTime]$epoch = '1970-01-01 00:00:00'
    }
    process {

        $ProxmoxNodeName | ForEach-Object {

            try {

                $data = Invoke-RestMethod `
                -Method Get `
                -Uri ($proxmoxApiBaseUri.AbsoluteUri + "nodes/$_/time") `
                -WebSession $ProxmoxWebSession | Select-Object -ExpandProperty data
                $data.time = $epoch.AddSeconds($data.time)
                $data.localtime = $epoch.AddSeconds($data.localtime)
                return $data
                
            }
            catch {

                throw $_.Exception

            }

        }

    }
    end { if ($SkipProxmoxCertificateCheck) { Enable-CertificateValidation } }

}