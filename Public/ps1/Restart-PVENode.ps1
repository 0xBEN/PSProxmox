function Restart-PVENode {

    [CmdletBinding()]
    Param (
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true
        )]
        [ProxmoxNode[]]
        $ProxmoxNode
    )
    begin {
        $body = @{command = 'reboot'}
    }
    process {

        $ProxmoxNode | ForEach-Object {
             
            $node = $_
            try {
                Send-PveApiRequest -Method Post -Uri ($ProxmoxApiBaseUri.AbsoluteUri + "nodes/$($node.node)/status") -Body $body
            }
            catch {
                Write-Error -Exception $_.Exception
            }    


        }

    }

}