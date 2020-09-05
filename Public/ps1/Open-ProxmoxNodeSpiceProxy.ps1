function Open-ProxmoxNodeSpiceProxy {

    [CmdletBinding()]
    Param (
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true
        )]
        [PSObject]
        $ProxmoxNode,

        [Parameter(
            Mandatory = $true,
            Position = 1
        )]
        [Int]
        $VMID,

        [Parameter(
            Mandatory = $true,
            Position = 2
        )]
        [ValidateNotNullOrEmpty()]
        [String]
        $OutFilePath,

        [Parameter(Position = 3)]
        [ValidateNotNullOrEmpty()]
        [String]
        $SpiceProxy = $ProxmoxApiBaseUri.Host
    )
    begin { 

        if ($SkipProxmoxCertificateCheck) {
            
            if ($PSVersionTable.PSEdition -ne 'Core') {
                Disable-CertificateValidation # Custom function to bypass X.509 cert checks
            }
            else {
                $NoCertCheckPSCore = $true
            }
        
        }
        $uri = $proxmoxApiBaseUri.AbsoluteUri + "nodes/$($ProxmoxNode.node)/qemu/$VMID/spiceproxy"

    }
    process {

        $body = @{proxy = $SpiceProxy}
        try {

            if ($NoCertCheckPSCore) {
                $spiceClientObject = Invoke-RestMethod `
                -Method Post `
                -Uri $uri `
                -SkipCertificateCheck `
                -Headers $ProxmoxCsrfToken `
                -Body $body `
                -WebSession $ProxmoxWebSession | Select-Object -ExpandProperty data    
            }
            else {
                $spiceClientObject = Invoke-RestMethod `
                -Method Post `
                -Uri $uri `
                -Headers $ProxmoxCsrfToken `
                -Body $body `
                -WebSession $ProxmoxWebSession | Select-Object -ExpandProperty data    
            }
            
            # Array of strings that will form the virt-viewer INI key=value file
            [array]$content = '[virt-viewer]'
            $content += $spiceClientObject | Get-Member -MemberType NoteProperty | Sort-Object Name -Descending | # Form an array of strings in the format of key=value
            ForEach-Object { $name = $_.Name ; $name + '=' + $spiceClientObject.$name }            
            $content | Out-File $OutFilePath -Encoding ascii -Force -ErrorAction Stop
            
            Start-Job -ScriptBlock {Invoke-Item $args} -ArgumentList $OutFilePath | Out-Null

        }
        catch {

            throw $_.Exception

        }

    }
    end { if ($SkipProxmoxCertificateCheck -and -not $NoCertCheckPSCore) { Enable-CertificateValidation } }

}