function Remove-PVENodeVM {

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
        [Int[]]
        $VMID,

        [Parameter(Position = 2)]
        [Switch]
        $Purge,

        [Parameter(Position = 3)]
        [Switch]
        $SkipLock
    )
    process {

        $ProxmoxNode | ForEach-Object {
             
            $node = $_
            $VMID | ForEach-Object {
                    
                try {
                    Send-PveApiRequest -Method Delete -Uri ($ProxmoxApiBaseUri.AbsoluteUri + "nodes/$($node.node)/qemu/$_") | 
                    Select-Object -ExpandProperty data
                }
                catch {
                    Write-Error -Exception $_.Exception
                }    

            }

        }

    }

}