function New-ProxmoxAuthCookie {

    [CmdletBinding()]
    Param (

        [Parameter(
            Mandatory = $true,
            Position = 0
        )]
        [System.Uri]
        $ServerUri,

        [Parameter(
            Mandatory = $true,
            Position = 1
        )]
        [ValidateNotNullOrEmpty()]
        [String]
        $Ticket

    )
    process {

        $Cookie = New-Object System.Net.Cookie
        $Cookie.Name = 'PVEAuthCookie'
        $Cookie.Value = $Ticket
        $Cookie.Domain = $ServerUri.DnsSafeHost
        $Cookie.Expires = (Get-Date).AddHours(2) # Lifecycle of a PVE Auth Ticket

        return $Cookie

    }

}