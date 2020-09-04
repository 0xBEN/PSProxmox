function Open-ProxmoxNodeSpiceProxy {

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $ProxmoxNodeName,

        [Parameter(Mandatory = $true)]
        [Int]
        $VMID,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $OutFilePath,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]
        $SpiceProxy = $ProxmoxApiBaseUri.Host
    )
    begin { if ($SkipProxmoxCertificateCheck) { Disable-CertificateValidation } }
    process {

        $body = @{proxy = $SpiceProxy}
        try {

            $spiceClientObject = Invoke-RestMethod `
            -Method Post `
            -Uri ($proxmoxApiBaseUri.AbsoluteUri + "nodes/$ProxmoxNodeName/qemu/$VMID/spiceproxy") `
            -Headers $ProxmoxCsrfToken `
            -Body $body `
            -WebSession $ProxmoxWebSession | Select-Object -ExpandProperty data
            
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
    end { if ($SkipProxmoxCertificateCheck) { Enable-CertificateValidation } }

}