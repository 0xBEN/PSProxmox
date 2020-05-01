function Get-ProxmoxAuthTicket {

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
    
    .EXAMPLE

    PS>Get-ProxmoxAuthTicket -ServerUri 'https://server.domain:8006' -ProxmoxCredential (Get-Credential)

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
        $ProxmoxCredential

    )
    begin {

        $username = $ProxmoxCredential.UserName
        $password = $ProxmoxCredential.GetNetworkCredential().Password
        $body = @{
            username = $username
            password = $password
        }

    }
    process {


        try {

            $apiCall = Invoke-RestMethod `
            -Method Post `
            -Uri $ServerUri.AbsoluteUri `
            -Body $body

        }
        catch {

            throw $_

        }

    }
    end {

        if ($apiCall) {

            return $apiCall | Select-Object CSRFPreventionToken, ticket, username

        }
        else {

            return

        }

    }

}