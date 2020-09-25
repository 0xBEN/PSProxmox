function Connect-PVEApi {

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

    .PARAMETER ApiKey

    System.String
    Should be in the format of: PVEAPIToken=username@realm!tokenName=UUID

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
    [CmdletBinding(DefaultParameterSetName = 'Credential')]
    Param (

        [Parameter(
            HelpMessage = 'The fully qualified URI of the server. Do not include the API path.',
            Mandatory = $true,
            Position = 0,
            ParameterSetName = 'Credential'
        )]
        [Parameter(
            HelpMessage = 'The fully qualified URI of the server. Do not include the API path.',
            Mandatory = $true,
            Position = 0,
            ParameterSetName = 'Token'
        )]
        [System.Uri]
        $ServerUri,

        [Parameter(
            HelpMessage = 'username@realm credential',
            Mandatory = $true,
            Position = 1,
            ParameterSetName = 'Credential'
        )]
        [PSCredential]
        $ProxmoxCredential,

        [Parameter(
            HelpMessage = 'PVEAPIToken=username@realm!tokenName=UUID',
            Mandatory = $true,
            Position = 1,
            ParameterSetName = 'Token'
        )]
        [ValidateNotNullOrEmpty()]
        [String]
        $ApiKey,

        [Parameter(ParameterSetName = 'Credential')]
        [Parameter(ParameterSetName = 'Token')]
        [Switch]
        $SkipCertificateValidation

    )
    begin {
        
        # Remove any module-scope variables in case the user is reauthenticating
        Remove-Variable `
        -Scope Script `
        -Name ProxmoxWebSession, ProxmoxApiToken, ProxmoxApiBaseUri, SkipProxmoxCertificateCheck, ProxmoxCsrfToken `
        -Force -ErrorAction SilentlyContinue | Out-Null

        # Setting the variables in this way allows them to be re-initialized upon new connections in the same shell
        if ($SkipCertificateValidation) {
            Set-Variable `
            -Name SkipProxmoxCertificateCheck `
            -Value $true `
            -Option ReadOnly `
            -Scope Script `
            -Force
        }
        else {
            Set-Variable `
            -Name SkipProxmoxCertificateCheck `
            -Value $false `
            -Option ReadOnly `
            -Scope Script `
            -Force
        }
        
        [System.Uri]$proxmoxApiBaseUri = $ServerUri.AbsoluteUri + 'api2/json/'

    }
    process {

        if ($PSCmdlet.ParameterSetName -eq 'Credential') { 

            $username = $ProxmoxCredential.UserName
            $password = $ProxmoxCredential.GetNetworkCredential().Password
            $body = @{
                username = $username
                password = $password
            }

            try {
                $request = Send-PveApiRequest -Method Post -Uri ($proxmoxApiBaseUri.AbsoluteUri + 'access/ticket') -Body $body -SessionVariable pveTicket
            }
            catch {
                throw $_.Exception
            }

        }
        else { # User is authenticating with API token

            Set-Variable `
            -Name ProxmoxApiToken `
            -Value @{ Authorization = $ApiKey } `
            -Option ReadOnly `
            -Scope Script `
            -Force
            
            try { 
                $request = Send-PveApiRequest -Method Get -Uri ($proxmoxApiBaseUri.AbsoluteUri + 'nodes')
            }
            catch {
                throw $_.Exception
            }

        }

    }
    end {

        if ($request) { # Authentication was successfull. Initialize this module-scope variable.
            Set-Variable `
            -Name ProxmoxApiBaseUri `
            -Value $proxmoxApiBaseUri `
            -Option ReadOnly `
            -Scope Script `
            -Force
        }
        else {
            return
        }

    }

}