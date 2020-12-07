function Update-PVENodeAptPackageIndex {

    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true
        )]
        [ProxmoxNode[]]
        $ProxmoxNode,

        [Parameter(
            Position = 1,    
            HelpMessage = 'Notify email for root@pam user regarding available updates.'
        )]
        [Switch]
        $Notify,

        [Parameter(
            Position = 2,
            HelpMessage = 'Suppress progress indicators.'
        )]
        [Switch]
        $Quiet
    )
    begin {
        
        $body = @{}
        if ($Notify.IsPresent) { $body.Add('notify', 1) }
        if ($Quiet.IsPresent) { $body.Add('quiet', 1) }
        
    }
    process {

        $ProxmoxNode | ForEach-Object {

            try {
                Send-PveApiRequest -Method Post -Uri ($ProxmoxApiBaseUri.AbsoluteUri + "nodes/$($_.node)/apt/update") -Body $body | 
                Select-Object -ExpandProperty data   
            }
            catch {
                Write-Error -Exception $_.Exception
            }

        }

    }

}