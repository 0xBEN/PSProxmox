function Confirm-ProxmoxApiConnection {

    [CmdletBinding()]
    Param ()
    process {

        if (-not $ProxmoxWebSession) {
            throw "User not authenticated to Proxmox API."
        }

        try {
            Get-ProxmoxApiVersion
        }
        catch {
            if ($_.Response.StatusDescription -like '*invalid PVE ticket*') { 
                throw "User not connected to Proxmox API." 
            }
        }

    }

}