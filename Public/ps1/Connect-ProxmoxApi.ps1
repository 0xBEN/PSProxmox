function Connect-ProxmoxApi {

    <#
    .SYNOPSIS

    Returns an auth ticket if authentication to Proxmox server is successful.

    .DESCRIPTION
    
    Returns an auth ticket if authentication to Proxmox server is successful.
    This ticket will be in PowerShell object notation and can be used in consecutive API calls.

    .PARAMETER  ServerUri
        
    System.Uri
    This is the fully qualified URI of the Proxmox server.
    Do not include the path to the API.

    .PARAMETER ProxmoxCredential

    System.Management.Automation.PSCredential
    This is the username@realm credential you will use to authenticate.

    .PARAMETER SkipCertificateValidation
    Switch
    Indicates the server's X509 certificate should not be validated.
    PowerShell will inherently drop the connection on insecure connections otherwise.
    
    .EXAMPLE

    PS>Connect-ProxmoxApi -ServerUri 'https://server.domain:8006' -ProxmoxCredential (Get-Credential)

    In this example the user is prompted to enter a username and password, which will be passed as input.
    Then, a connection attempt is made to the Proxmox server API for a ticket using this credential.
        
    .INPUTS
       
    System.Uri
    System.Management.Automation.PSCredential

    .OUTPUTS
        
    PSObject
    #>
    [CmdletBinding()]
    Param (

        [Parameter(
            HelpMessage = 'The fully qualified URI of the server. Do not include the API path.',
            Mandatory = $true,
            Position = 0
        )]
        [System.Uri]
        $ServerUri,

        [Parameter(
            HelpMessage = 'username@realm credential',
            Mandatory = $true,
            Position =1
        )]
        [PSCredential]
        $ProxmoxCredential,

        [Parameter()]
        [Switch]
        $SkipCertificateValidation

    )
    begin {

        if ($SkipCertificateValidation) { Disable-CertificateValidation }
        $username = $ProxmoxCredential.UserName
        $password = $ProxmoxCredential.GetNetworkCredential().Password
        $body = @{
            username = $username
            password = $password
        }

        [System.Uri]$proxmoxApiBaseUri = $ServerUri.AbsoluteUri + 'api2/json/'

    }
    process {

        try {

            $apiCall = Invoke-RestMethod `
            -Method Post `
            -Uri ($proxmoxApiBaseUri.AbsoluteUri + 'access/ticket') `
            -Body $body `
            -SessionVariable pveTicket

        }
        catch {

            throw $_.Exception

        }

    }
    end {

        if ($SkipCertificateValidation) { Enable-CertificateValidation }
        if ($apiCall) {

            $cookie = New-ProxmoxAuthCookie $ServerUri $apiCall.data.ticket
            $pveTicket.Cookies.Add($cookie)

            # Setting the variables in this way allows them to be re-initialized upon new connections in the same shell
            Set-Variable `
            -Name ProxmoxApiBaseUri `
            -Value $proxmoxApiBaseUri `
            -Option ReadOnly `
            -Scope Global `
            -Force

            Set-Variable `
            -Name ProxmoxWebSession `
            -Value $pveTicket `
            -Option ReadOnly `
            -Scope Global `
            -Force

            Set-Variable `
            -Name ProxmoxCsrfToken `
            -Value @{ 'CSRFPreventionToken' = $apiCall.data.CSRFPreventionToken } `
            -Option ReadOnly `
            -Scope Global `
            -Force

            if ($SkipCertificateValidation) {

                Set-Variable `
                -Name SkipProxmoxCertificateCheck `
                -Value $true `
                -Option ReadOnly `
                -Scope Global `
                -Force

            }
            else {

                Set-Variable `
                -Name SkipProxmoxCertificateCheck `
                -Value $false `
                -Option ReadOnly `
                -Scope Global `
                -Force

            }

        }
        else {

            return

        }

    }

}