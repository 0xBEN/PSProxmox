function Get-PVENodeVMOSInfo {

    [CmdletBinding()]
    Param (
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true
        )]
        [ProxmoxNode[]]
        $ProxmoxNode,

        [Parameter(
            Mandatory = $true,
            Position = 1
        )]
        [String[]]
        $VMID
    )
    process {

        $ProxmoxNode | ForEach-Object {
            
            $VMID | ForEach-Object {

                try {
                    Send-PveApiRequest -Method Get -Uri ($ProxmoxApiBaseUri.AbsoluteUri + "nodes/$($_.node)/qemu/$_/agent/get-osinfo/") | 
                    Select-Object -ExpandProperty data | Select-Object -ExpandProperty result
                }
                catch {

                    if ($_.Exception.Response.StatusDescription -eq 'QEMU guest agent is not running') {
                        throw 'QEMU guest agent is not running'
                    }
                    else {
                        $_ | Write-Error
                    }

                }

            }

        }

    }

}
