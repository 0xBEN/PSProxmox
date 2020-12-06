function New-PVENodeContainer {

    [CmdletBinding()]
    [Alias('npvenlxc')]
    Param (
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [ProxmoxNode[]]
        $ProxmoxNode,

        [Parameter(
            Mandatory = $true,
            HelpMessage = 'OS template or backup file.'
        )]
        [String]
        $OSTemplate,

        [Parameter(
            Mandatory = $true,
            HelpMessage = 'Unique ID of the guest.'
        )]
        [Int]
        $ContainerId,

        [Parameter(HelpMessage = 'OS architecture type.')]
        [ValidateSet('amd64', 'i386', 'arm64', 'armhf')]
        [String]
        $Architecture,

        [Parameter(HelpMessage = 'Override container I/O bandwidth.')]
        [Int]
        $BandwidthLimitKbps,

        [Parameter(HelpMessage = 'Set the default console for the container. Console resolves to /dev/console. Shell resolves to nologin shell and opens directly in the container.')]
        [ValidateSet('shell', 'console', 'tty')]
        [String]
        $DefaultConsoleMode,

        [Parameter(HelpMessage = 'Attach a console device (/dev/console) to the container')]
        [Bool]
        $AddConsoleDevice,

        [Parameter(HelpMessage = 'Number of CPU cores assigned to the container. A container can use all available cores by default.')]
        [ValidateRange(1,8192)]
        [Int]
        $Cores,

        [Parameter(HelpMessage = 'If a container has 2 CPUs, it has a total of 2 CPU time available. 0 indicates no limit.')]
        [ValidateRange(0,8192)]
        [Int]
        $LimitCPUTime,

        [Parameter(HelpMessage = 'The higher the value, the higher CPU priority assigned by the kernel.')]
        [ValidateRange(0,500000)]
        [Long]
        $CPUPriority,

        [Parameter(HelpMessage = 'This enables debug log-level on container start.')]
        [Bool]
        $DebugModeEnabled,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]
        $ContainerDescription,

        [Parameter(HelpMessage = 'Consult the API documentation for argument formatting on features.')]
        [ValidateNotNullOrEmpty()]
        [String]
        $AdvancedFeatures,

        [Parameter(HelpMessage = 'If container ID already exists, this parameter overwrites it.')]
        [Bool]
        $Force,

        [Parameter(HelpMessage = 'Script that will be executed during the containers lifecycle.')]
        [ValidateNotNullOrEmpty()]
        [String]
        $HookScript,

        [Parameter(HelpMessage = 'Set a hostname for the container.')]
        [ValidateNotNullOrEmpty()]
        [String]
        $Hostname,

        [Parameter(HelpMessage = 'Ignore errors when extracting the template.')]
        [Bool]
        $IgnoreUnpackErrors,

        [Parameter()]
        [ValidateSet('backup', 'create', 'destroyed', 'disk', 'fstrim', 'migrate', 'mounted', 'rollback', 'snapshot', 'snapshot-delete')]
        [String]
        $Lock,

        [Parameter(HelpMessage = 'Amount of memory for the container in MB.')]
        [ValidateScript({$_ -ge 16})]
        [Long]
        $MemoryMB,

        [Parameter(HelpMessage ='Example: @{0 = "key1=value1,key2=value2,key3=value3"}. In the hashtable, the key is the Mountpoint ID; the value is the argument(s). Refer to the API documentation for argument formatting.')]
        [ValidateScript({
            $validationErrors = @()
            $_ | ForEach-Object {
                $key = $_.GetEnumerator().Name
                if ($key -match '\D') { $validationErrors += 'One or more hashtables contains a key that is not an integer.' }
            }
            if ($validationErrors) { throw "The following error(s) occurred:`n$($validationErrors | Out-String)." }
            else { return $true }
        })]
        [Hashtable[]]
        $Mountpoint,

        [Parameter(HelpMessage = 'Set the DNS server IP address for the container.')]
        [ValidateNotNullOrEmpty()]
        [String]
        $Nameserver,

        [Parameter(HelpMessage ='Example: @{0 = "key1=value1,key2=value2,key3=value3"}. In the hashtable, the key is the Network Interface ID; the value is the argument(s). Refer to the API documentation for argument formatting.')]
        [ValidateScript({
            $validationErrors = @()
            $_ | ForEach-Object {
                $key = $_.GetEnumerator().Name
                if ($key -match '\D') { $validationErrors += 'One or more hashtables contains a key that is not an integer.' }
            }
            if ($validationErrors) { throw "The following error(s) occurred:`n$($validationErrors | Out-String)." }
            else { return $true }
        })]
        [Hashtable[]]
        $ConfigureNetworkDevice,

        [Parameter(HelpMessage = 'Start the container with the system boot.')]
        [Bool]
        $StartOnBoot,

        [Parameter(HelpMessage = 'This is used to setup the configuration inside the container and corresponds to LXC setup scripts in /usr/share/lxc/config/<ostype>.common.conf. Unmanaged can be used to skip OS-specific setup.')]
        [ValidateSet('debian', 'ubuntu', 'centos', 'fedora', 'opensuse', 'archlinux', 'alpine', 'gentoo', 'unmanaged')]
        [String]
        $OSType,

        [Parameter(HelpMessage = 'Set the password for the root user in the container.')]
        [System.Security.SecureString]
        $RootPassword,

        [Parameter(HelpMessage = 'Add the container to a specified pool.')]
        [ValidateNotNullOrEmpty()]
        [String]
        $AddToPool,

        [Parameter(HelpMessage = "Prevents the container's disk from being removed or updated.")]
        [Bool]
        $Protection,

        [Parameter(HelpMessage = 'Indicate that the creation of this container is a restore task.')]
        [Bool]
        $RestoreContainer,

        [Parameter(HelpMessage = 'Consult the API documentation for argument formatting on volume argument.')]
        [ValidateNotNullOrEmpty()]
        [String]
        $RootFileSystem,

        [Parameter(HelpMessage = 'Set the DNS search domain for the container. Will use the host settings if unspecified.')]
        [ValidateNotNullOrEmpty()]
        [String]
        $DNSSearchDomain,

        [Parameter(HelpMessage = 'One key per line. OpenSSH format.')]
        [ValidateNotNullOrEmpty()]
        [String]
        $PublicSSHKey,

        [Parameter(HelpMessage = 'Start the container after successful creation.')]
        [Bool]
        $StartOnCreate,

        [Parameter(HelpMessage = 'Consult the API documentation for argument formatting on startup order.')]
        [ValidateNotNullOrEmpty()]
        [String]
        $StartUpOrder,

        [Parameter(HelpMessage = 'Default PVE volume to be used for storage.')]
        [ValidateNotNullOrEmpty()]
        [String]
        $NodeStorageVolume,

        [Parameter()]
        [Long]
        $SwapMemoryMB,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]
        $Tags,

        [Parameter()]
        [Bool]
        $ConvertToTemplate,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]
        $ContainerTimezone,

        [Parameter(HelpMessage = 'Number of concurrent shells available to the container.')]
        [ValidateRange(0,6)]
        [Byte]
        $TTYLimit,

        [Parameter(HelpMessage = 'Assign a unique, random Ethernet address.')]
        [Bool]
        $UniqueAddress,

        [Parameter()]
        [Bool]
        $UnprivilegedContainer
    )
    begin{

        $body = @{}
        if ($PSBoundParameters['ContainerId']) { $body.Add('vmid', $PSBoundParameters['ContainerId']) }
        if ($PSBoundParameters['OSTemplate']) { $body.Add('ostemplate', $PSBoundParameters['OSTemplate']) }
        if ($PSBoundParameters['Architecture']) { $body.Add('arch', $PSBoundParameters['Architecture']) }
        if ($PSBoundParameters['BandwidthLimitKbps']) { $body.Add('bwlimit', $PSBoundParameters['BandwidthLimitKbps']) }
        if ($PSBoundParameters['DefaultConsoleMode']) { $body.Add('cmode', $PSBoundParameters['DefaultConsoleMode']) }
        if ($PSBoundParameters['AddConsoleDevice']) { $body.Add('console', $PSBoundParameters['AddConsoleDevice']) }
        if ($PSBoundParameters['Cores']) { $body.Add('cores', $PSBoundParameters['Cores']) }
        if ($PSBoundParameters['LimitCPUTime']) { $body.Add('cpulimit', $PSBoundParameters['LimitCPUTime']) }
        if ($PSBoundParameters['CPUPriority']) { $body.Add('cpuunits', $PSBoundParameters['CPUPriority']) }
        if ($PSBoundParameters['DebugModeEnabled']) { $body.Add('debug', $PSBoundParameters['DebugModeEnabled']) }
        if ($PSBoundParameters['ContainerDescription']) { $body.Add('description', $PSBoundParameters['ContainerDescription']) }
        if ($PSBoundParameters['AdvancedFeatures']) { $body.Add('features', $PSBoundParameters['AdvancedFeatures']) }
        if ($PSBoundParameters['Force']) { $body.Add('force', $PSBoundParameters['Force']) }
        if ($PSBoundParameters['HookScript']) { $body.Add('hookscript', $PSBoundParameters['HookScript']) }
        if ($PSBoundParameters['Hostname']) { $body.Add('hostname', $PSBoundParameters['Hostname']) }
        if ($PSBoundParameters['IgnoreUnpackErrors']) { $body.Add('ignore-unpack-errors', $PSBoundParameters['IgnoreUnpackErrors']) }
        if ($PSBoundParameters['Lock']) { $body.Add('lock', $PSBoundParameters['Lock']) }
        if ($PSBoundParameters['MemoryMB']) { $body.Add('memory', $PSBoundParameters['MemoryMB']) }
        if ($PSBoundParameters['Mountpoint']) {
            $PSBoundParameters['Mountpoint'].GetEnumerator() | ForEach-Object {
                $hashtable = $_
                $body.Add("mp[$($hashtable.Keys)]", $hashtable.Values) # Format should be that of param[n]=key1=value1,key2=value2
            }
        }
        if ($PSBoundParameters['Nameserver']) { $body.Add('nameserver', $PSBoundParameters['Nameserver']) }
        if ($PSBoundParameters['ConfigureNetworkDevice']) {
            $PSBoundParameters['ConfigureNetworkDevice'].GetEnumerator() | ForEach-Object {
                $hashtable = $_
                $body.Add("net[$($hashtable.Keys)]", $hashtable.Values) # Format should be that of param[n]=key1=value1,key2=value2
            }
        }
        if ($PSBoundParameters['StartOnBoot']) { $body.Add('onboot', $PSBoundParameters['StartOnBoot']) }
        if ($PSBoundParameters['OSType']) { $body.Add('ostype', $PSBoundParameters['OSType']) }
        if ($PSBoundParameters['RootPassword']) { $body.Add('password', ($PSBoundParameters['RootPassword'] | Read-SecureString)) }
        if ($PSBoundParameters['AddToPool']) { $body.Add('pool', $PSBoundParameters['AddToPool']) }
        if ($PSBoundParameters['Protection']) { $body.Add('protection', $PSBoundParameters['Protection']) }
        if ($PSBoundParameters['RestoreContainer']) { $body.Add('restore', $PSBoundParameters['RestoreContainer']) }
        if ($PSBoundParameters['RootFileSystem']) { $body.Add('rootfs', $PSBoundParameters['RootFileSystem']) }
        if ($PSBoundParameters['DNSSearchDomain']) { $body.Add('searchdomain', $PSBoundParameters['DNSSearchDomain']) }
        if ($PSBoundParameters['PublicSSHKey']) { $body.Add('ssh-public-keys', $PSBoundParameters['PublicSSHKey']) }
        if ($PSBoundParameters['StartOnCreate']) { $body.Add('start', $PSBoundParameters['StartOnCreate']) }
        if ($PSBoundParameters['StartUpOrder']) { $body.Add('startup', $PSBoundParameters['StartUpOrder']) }
        if ($PSBoundParameters['NodeStorageVolume']) { $body.Add('storage', $PSBoundParameters['NodeStorageVolume']) }
        if ($PSBoundParameters['SwapMemoryMB']) { $body.Add('swap', $PSBoundParameters['SwapMemoryMB']) }
        if ($PSBoundParameters['Tags']) { $body.Add('tags', $PSBoundParameters['Tags']) }
        if ($PSBoundParameters['ConvertToTemplate']) { $body.Add('template', $PSBoundParameters['ConvertToTemplate']) }
        if ($PSBoundParameters['ContainerTimezone']) { $body.Add('timezone', $PSBoundParameters['ContainerTimezone']) }
        if ($PSBoundParameters['TTYLimit']) { $body.Add('tty', $PSBoundParameters['TTYLimit']) }
        if ($PSBoundParameters['UniqueAddress']) { $body.Add('unique', $PSBoundParameters['UniqueAddress']) }
        if ($PSBoundParameters['UnprivilegedContainer']) { $body.Add('unprivileged', $PSBoundParameters['UnprivilegedContainer']) }

    }
    process {

        $ProxmoxNode | ForEach-Object {
             
            $node = $_                  
            try {
                Send-PveApiRequest -Method Post -Uri ($ProxmoxApiBaseUri.AbsoluteUri + "nodes/$($node.node)/lxc") -Body $body | 
                Select-Object -ExpandProperty data
            }
            catch {
                Write-Error -Exception $_.Exception
            }    

        }

    }

}