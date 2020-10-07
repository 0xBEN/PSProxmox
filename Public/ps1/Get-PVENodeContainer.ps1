function Get-PVENodeContainer {

    [CmdletBinding()]
    Param (
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true
        )]
        [ProxmoxNode[]]
        $ProxmoxNode,

        [Parameter(Position = 1)]
        [Int[]]
        $ContainerId
    )
    process {

        $ProxmoxNode | ForEach-Object {
             
            $node = $_
            if ($ContainerId) {

                $ContainerId | ForEach-Object {
                    
                    try {
                        Send-PveApiRequest -Method Get -Uri ($ProxmoxApiBaseUri.AbsoluteUri + "nodes/$($node.node)/lxc/$_/status/current") | 
                        Select-Object -ExpandProperty data
                    }
                    catch {
                        Write-Error -Exception $_.Exception
                    }    

                }

            }
            else {
                 
                try {
                    Send-PveApiRequest -Method Get -Uri ($ProxmoxApiBaseUri.AbsoluteUri + "nodes/$($node.node)/lxc") | Select-Object -ExpandProperty data
                }
                catch {
                    throw $_.Exception
                }

            }

        }

    }

}
