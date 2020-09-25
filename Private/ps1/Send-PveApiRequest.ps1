function Send-PveApiRequest {

    [CmdletBinding()]
    Param (
        [Parameter(Position = 0)]
        [Microsoft.PowerShell.Commands.WebRequestMethod]
        $Method = 'Get',

        [Parameter(
            Mandatory = $true,
            Position = 1
        )]
        [System.Uri]
        $Uri,

        [Parameter(Position = 3)]
        [System.Object]
        $Body,

        [Parameter(Position = 4)]
        [String]
        $SessionVariable
    )
    begin {
        
        if ($SkipProxmoxCertificateCheck) { # Script-scope variable used to indicate that the server certificate should never be checked on any call        
            if ($PSVersionTable.PSEdition -ne 'Core') { Disable-CertificateValidation } # Custom function to bypass X.509 cert checks
            else { $NoCertCheckPSCore = $true }        
        }

    }
    process {

        if ($SessionVariable) { # User is sending authentication request

            try {

                if ($NoCertCheckPSCore) {
                    $request = Invoke-RestMethod `
                    -Method $Method `
                    -Uri $uri `
                    -Body $Body ` # In my experience, body can be an empty variable and PowerShell won't throw an error
                    -SessionVariable $SessionVariable `
                    -SkipCertificateCheck `
                    -AllowUnencryptedAuthentication
                }
                else {
                    $request = Invoke-RestMethod `
                    -Method $Method `
                    -Uri $uri `
                    -Body $Body `
                    -SessionVariable $SessionVariable
                }

                if ($request) {
                    $cookie = New-PveAuthCookie $ServerUri $request.data.ticket
                    $pveTicket.Cookies.Add($cookie)
                    Set-Variable `
                    -Name ProxmoxWebSession `
                    -Value $pveTicket `
                    -Option ReadOnly `
                    -Scope Script `
                    -Force
        
                    Set-Variable `
                    -Name ProxmoxCsrfToken `
                    -Value @{ 'CSRFPreventionToken' = $request.data.CSRFPreventionToken } `
                    -Option ReadOnly `
                    -Scope Script `
                    -Force

                    return $request
                }

            }
            catch {

                throw $_

            }

        }
        elseif (-not $ProxmoxWebSession -and -not $ProxmoxApiToken) {
            
            throw "User not authenticated to Proxmox API."
            
        }
        elseif ($ProxmoxWebSession) { # User has authenticated with username and password

            try {
                
                if ($Method -ne 'Get') { # Any method other than GET requires the CSRF token in the request headers

                    if ($NoCertCheckPSCore) {
                        Invoke-RestMethod `
                        -Method $Method `
                        -Uri $uri `
                        -Headers $ProxmoxCsrfToken `
                        -Body $Body `
                        -WebSession $ProxmoxWebSession `
                        -SkipCertificateCheck `
                        -AllowUnencryptedAuthentication
                    }
                    else {
                        Invoke-RestMethod `
                        -Method $Method `
                        -Uri $uri `
                        -Headers $ProxmoxCsrfToken `
                        -Body $Body `
                        -WebSession $ProxmoxWebSession
                    }

                }
                else {

                    if ($NoCertCheckPSCore) {
                        Invoke-RestMethod `
                        -Method $Method `
                        -Uri $uri `
                        -Headers $Headers `
                        -Body $Body `
                        -WebSession $ProxmoxWebSession `
                        -SkipCertificateCheck `
                        -AllowUnencryptedAuthentication
                    }
                    else {
                        Invoke-RestMethod `
                        -Method $Method `
                        -Uri $uri `
                        -Headers $Headers `
                        -Body $Body `
                        -WebSession $ProxmoxWebSession
                    }

                }

            }
            catch {

                throw $_

            }

        }
        else { # User is sending request with an API token

            try {

                if ($NoCertCheckPSCore) {
                    Invoke-RestMethod `
                    -Method $Method `
                    -Uri $Uri `
                    -Headers $ProxmoxApiToken `
                    -Body $Body `
                    -SkipCertificateCheck
                }
                else {
                    Invoke-RestMethod `
                    -Method $Method `
                    -Uri $Uri `
                    -Headers $ProxmoxApiToken `
                    -Body $Body `
                }

            }
            catch {

                throw $_
                
            }

        }

    }
    end {

        if ($SkipProxmoxCertificateCheck -and -not $NoCertCheckPSCore) { Enable-CertificateValidation } 

    }

}