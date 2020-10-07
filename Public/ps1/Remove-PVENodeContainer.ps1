function Remove-PVENodeContainer {

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
        $ContainerId,

        [Parameter(Position = 2)]
        [Switch]
        $Purge,

        [Parameter(Position = 3)]
        [Switch]
        $Force
    )
    process {

        $ProxmoxNode | ForEach-Object {
             
            $node = $_
            $ContainerId | ForEach-Object {
                    
                try {
                    Send-PveApiRequest -Method Delete -Uri ($ProxmoxApiBaseUri.AbsoluteUri + "nodes/$($node.node)/lxc/$_") | 
                    Select-Object -ExpandProperty data
                }
                catch {
                    Write-Error -Exception $_.Exception
                }    

            }

        }

    }

}