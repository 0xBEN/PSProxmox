function New-PVENodeVM {

    [CmdletBinding()]
    [Alias('npvenvm')]
    Param (
        [Parameter(
            ValueFromPipeline = $true,
            Mandatory = $true
        )]
        [ProxmoxNode[]]
        $ProxmoxNode,

        [Parameter(Mandatory = $true)]
        [Int]
        $VMID,

        [Parameter()]
        [Bool]
        $EnableACPI,

        [Parameter(HelpMessage = 'Example: enabled=1,fstrim_cloned_disks=0,type=virtio. Refer to API documentation for more information.')]
        [ValidateNotNullOrEmpty()]
        [String]
        $QEMUAgentOptions,

        [Parameter(HelpMessage = 'Virtual processor architecture. If parameter not passed, defaults to the host architecture.')]
        [ValidateSet('x86_64', 'aarch64')]
        [String]
        $Architecture,

        [Parameter(HelpMessage = 'Defines the backup archive. System path to a .tar or .vma file, or Proxmox storage backup volume identifier.')]
        [ValidateNotNullOrEmpty()]
        [String]
        $Archive,

        [Parameter(HelpMessage = 'Arguments passed to KVM. Example: -no-reboot -no-hpet. Recommended for use by experts only.')]
        [ValidateNotNullOrEmpty()]
        [String]
        $KVMArguments,

        [Parameter(HelpMessage = 'Configure an audio device. Usefule in combination with QXL or SPICE.')]
        [ValidateNotNullOrEmpty()]
        [String]
        $ConfigureAudioDevice,

        <# Per API documentation, this parameter is currently ignored by the API
        [Parameter()]
        [Bool]
        $AutoStartOnCrash,
        #>

        [Parameter(HelpMessage = 'Target RAM in MB for the VM to balloon to. Value of 0 disables the balloon driver.')]
        [Long]
        $BalloonMemMB,

        [Parameter()]
        [ValidateSet('seabios', 'ovmf')]
        [String]
        $BIOS,

        [Parameter(HelpMessage = 'Specify the VM boot order sequence. Example: order=deviceName;deviceName;deviceName')]
        [ValidateNotNullOrEmpty()]
        [String]
        $VMBootOrder,

        [Parameter(HelpMessage = 'Limit the bit rate a VM can be resotred from storage.')]
        [Long]
        $BandwithLimitKiBs,

        [Parameter(HelpMessage = 'cloud-init: Specify custom files to replace automatically generated ones at start. Exmaple: meta=<volume>, network=<volume>, user=<volume>')]
        [ValidateNotNullOrEmpty()]
        [String]
        $CloudInitCustomFile,

        [Parameter(HelpMessage = 'cloud-init: Password assigned to the user. Recommend SSH keys instead. Older versions of cloud-init do not support hashed passwords.')]
        [ValidateNotNullOrEmpty()]
        [System.Security.SecureString]
        $CloudInitPassword,

        [Parameter(HelpMessage = 'cloud-init: Specifies the cloud-init configuration format. Depends on the guest operating system type. Example: Use [nocloud] for Linux, [configdrive2] for Windows.')]
        [ValidateSet('configdrive2', 'nocloud')]
        [String]
        $CloudInitType,

        [Parameter(HelpMessage = 'cloud-init: Specify the username for which to change the SSH keys and password instead of the default user.')]
        [ValidateNotNullOrEmpty()]
        [String]
        $CloudInitUser,

        [Parameter(HelpMessage = 'Number of CPU cores per socket.')]
        [ValidateScript({ $_ -ge 1})]
        [Byte]
        $CoresPerSocket,

        [Parameter(HelpMessage = 'Emulated CPU type. Refer to API documentation for argument formatting.')]
        [ValidateNotNullOrEmpty()]
        [String]
        $CPUType,

        [Parameter(HelpMessage = 'Limit CPU usage. Example: If a computer has 2 CPUs, it has a total of 2 CPU time. A value of 0 indicates no CPU limit.')]
        [Byte]
        $CPULimit,

        [Parameter(HelpMessage = 'CPU priority for a VM, based on kernel fair scheduler. The larger the number, the higher CPU priority. Number is relative to weights of all other running VMs.')]
        [ValidateRange(2, 262144)]
        [Int]
        $CPUPriority,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]
        $VMDescription,

        [Parameter(HelpMessage = 'Configure a disk for storing EFI variables. Refer to API documentation for argument formatting.')]
        [ValidateNotNullOrEmpty()]
        [String]
        $EFIDisk,

        [Parameter(HelpMessage = 'Allow overwrite of existing VM with same ID number.')]
        [Bool]
        $Force,

        [Parameter(HelpMessage = 'Freeze CPU at startup.')]
        [Bool]
        $FreezeCPU,

        [Parameter(HelpMessage = "Script that will be executed during varios steps in the VM's lifetime.")]
        [ValidateNotNullOrEmpty()]
        [String]
        $HookScript,

        [Parameter(HelpMessage ='Example: @{0 = "host=HOSTPCIID,legacy-igd=0,mdev=string"}. In the hashtable, the key is the host PCI ID number; the value is the argument(s). Map host PCI devices into guest. This option allows direct access to host hardware and will prevent migrations of this VM. Use with caution. Refer to API documentation for argument formatting.')]
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
        $MapHostPCIDevices,

        [Parameter(HelpMessage = 'Selectively enable hotplug features. Comma separated list of values are: network, disk, cpu, memory, and usb. 0 disables hotplug completely. 1 is an alias for the default arguments: network, disk, usb.')]
        [ValidateNotNullOrEmpty()]
        [String]
        $HotPlugFeatures,

        [Parameter()]
        [ValidateSet('any', '2', '1024')]
        [String]
        $MemoryHugePagesOption,

        [Parameter(HelpMessage ='Example: @{0 = "key1=value1,key2=value2,key3=value3"}. In the hashtable, the key is the IDE device ID; the value is the argument(s). Use a volume as an IDE hard disk or CD-ROM. Per the API documentation, a limit of 0 to 3 IDE devices can be speified. Refer to API documentation for argument formatting.')]
        [ValidateScript({
            $validationErrors = @()
            $_ | ForEach-Object {
                $key = $_.GetEnumerator().Name
                if ($key -match '\D') { $validationErrors += 'One or more hashtables contains a key that is not an integer.' }
                elseif ($key -lt 0 -or $key -gt 3) { $validationErrors += 'One ore more hashtables contains a key that is an integer outside the range of 0 to 3.'}
            }
            if ($validationErrors) { throw "The following error(s) occurred:`n$($validationErrors | Out-String)." }
            else { return $true }
        })]
        [Hashtable[]]
        $IDEVolumeOptions,

        [Parameter(HelpMessage ='Example: @{0 = "key1=value1,key2=value2,key3=value3"}. In the hashtable, the key is the Network Interface ID; the value is the argument(s). cloud-init: Specify the gateway and IP address for an interface. Refer to the API documentation for argument formatting.')]
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
        $IPConfig,

        [Parameter(HelpMessage = 'Inter-VM shared memory. Useful for direct communication between VMs or to the host. Refer to API documentation for argument formatting.')]
        [ValidateNotNullOrEmpty()]
        [String]
        $InterVMSharedMemory,

        [Parameter(HelpMessage = 'Use together with the hugepages parameter. If enabled, hugepages will not be deleted after VM shutdown and can be used for subsequent starts.')]
        [Bool]
        $PersistHugePages,

        [Parameter(HelpMessage = 'Keyboard layout for VNC server. Default is read from /etc/pve/datacenter.cfg')]
        [ValidateSet('de', 'de-ch', 'da', 'en-gb', 'en-us', 'es', 'fi', 'fr', 'fr-be', 'fr-ca', 'fr-ch', 'hu', 'is', 'it', 'ja', 'lt', 'mk', 'nl', 'no', 'pl', 'pt', 'pt-br', 'sv', 'sl', 'tr')]
        [String]
        $VNCKeyboardLayout,

        [Parameter()]
        [Bool]
        $EnableKVMHardwarVirtualization,

        [Parameter(HelpMessage = 'This is enabled by default if guest uses Microsoft OS.')]
        [Bool]
        $SetRealClockToLocalTime,

        [Parameter()]
        [ValidateSet('backup', 'clone', 'create', 'migrate', 'rollback', 'snapshot', 'snapshot-delete', 'suspending', 'suspended')]
        [String]
        $VMLockType,

        [Parameter(HelpMessage = 'Refer to API documentation for argument formatting.')]
        [ValidateNotNullOrEmpty()]
        [String]
        $QEMUMachineType,

        [Parameter(HelpMessage = 'Amount of RAM for the VM in MB. This is the maximum available memory when using the ballooning driver.')]
        [ValidateScript({ $_ -ge 16})]
        [Long]
        $VMMemoryMB,

        [Parameter(HelpMessage = 'Max tolerated downtime -- in seconds -- for migrations.')]
        [Decimal]
        $MaxMigrationDownTimeSeconds,

        [Parameter(HelpMessage = 'Maximum migration speed in MB/s. 0 indicates no speed limit.')]
        [Long]
        $MigrationSpeedLimitMBs,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]
        $VMName,

        [Parameter(HelpMessage = 'cloud-init: Set the DNS server IP address for a VM.')]
        [ValidateNotNullOrEmpty()]
        [String]
        $NameServer,

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

        [Parameter()]
        [Bool]
        $EnableNUMA,

        [Parameter(HelpMessage ='Example: @{0 = "key1=value1,key2=value2,key3=value3"}. In the hashtable, the key is the CPU ID; the value is the argument(s). Refer to API documentation for argument formatting.')]
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
        $ConfigureNUMATopology,

        [Parameter()]
        [Bool]
        $StartVMAtSystemBoot,

        [Parameter(HelpMessage = 'other: unspecified OS; wxp: Windows XP; w2k: Windows 2000; w2k3: Windows 2003; w2k8: Windows 2008; wvista: Windows Vista; win7: Windows 7; win8: Windows 8; win10: Windows 10; l24: Linux Kernel 2.4; l26: Linux Kernel 2.6; solaris: Solaris/OpenSolaris/OpenIndiana kernel')]
        [ValidateSet('other', 'wxp', 'w2k', 'w2k3', 'w2k8', 'wvista', 'win7',' win8', 'win10', 'l24', 'l26', 'solaris')]
        [String]
        $GuestOSType,

        [Parameter(HelpMessage ='Example: @{0 = "key1=value1,key2=value2,key3=value3"}. In the hashtable, the key is the Parallel device ID; the value is the argument(s). Map host parallel devices. Use with caution. Refer to API documentation for argument formatting.')]
        [ValidateScript({
            $validationErrors = @()
            $_ | ForEach-Object {
                $key = $_.GetEnumerator().Name
                if ($key -match '\D') { $validationErrors += 'One or more hashtables contains a key that is not an integer.' }
                elseif ($key -lt 0 -or $key -gt 2) { $validationErrors += 'One ore more hashtables contains a key that is an integer outside the range of 0 to 2.'}
            }
            if ($validationErrors) { throw "The following error(s) occurred:`n$($validationErrors | Out-String)." }
            else { return $true }
        })]
        [Hashtable[]]
        $MapHostParallelDevices,

        [Parameter(HelpMessage = 'Add VM to a specified pool.')]
        [ValidateNotNullOrEmpty()]
        [String]
        $AddToPool,

        [Parameter(HelpMessage = 'If turned on, this disables the option to remove the VM and disk.')]
        [Bool]
        $ProtectVM,

        [Parameter(HelpMessage = 'Close the shell connection on VM reboot.')]
        [Bool]
        $CloseShellOnReboot,

        [Parameter(HelpMessage = 'Refer to API documentation for argument formatting.')]
        [ValidateNotNullOrEmpty()]
        [String]
        $VirtIORandomNumberGenerator,

        [Parameter(HelpMessage ='Example: @{0 = "key1=value1,key2=value2,key3=value3"}. In the hashtable, the key is the SATA device ID; the value is the argument(s). Use a volume as an SATA hard disk or CD-ROM. Per the API documentation, a limit of 0 to 5 SATA devices can be speified. Refer to API documentation for argument formatting.')]
        [ValidateScript({
            $validationErrors = @()
            $_ | ForEach-Object {
                $key = $_.GetEnumerator().Name
                if ($key -match '\D') { $validationErrors += 'One or more hashtables contains a key that is not an integer.' }
                elseif ($key -lt 0 -or $key -gt 5) { $validationErrors += 'One ore more hashtables contains a key that is an integer outside the range of 0 to 5.'}
            }
            if ($validationErrors) { throw "The following error(s) occurred:`n$($validationErrors | Out-String)." }
            else { return $true }
        })]
        [Hashtable[]]
        $SATAVolumeOptions,

        [Parameter(HelpMessage ='Example: @{0 = "key1=value1,key2=value2,key3=value3"}. In the hashtable, the key is the SCSI device ID; the value is the argument(s). Use a volume as an SCSI hard disk or CD-ROM. Per the API documentation, a limit of 0 to 30 SCSI devices can be speified. Refer to API documentation for argument formatting.')]
        [ValidateScript({
            $validationErrors = @()
            $_ | ForEach-Object {
                $key = $_.GetEnumerator().Name
                if ($key -match '\D') { $validationErrors += 'One or more hashtables contains a key that is not an integer.' }
                elseif ($key -lt 0 -or $key -gt 30) { $validationErrors += 'One ore more hashtables contains a key that is an integer outside the range of 0 to 30.'}
            }
            if ($validationErrors) { throw "The following error(s) occurred:`n$($validationErrors | Out-String)." }
            else { return $true }
        })]
        [Hashtable[]]
        $SCSIVolumeOptions,

        [Parameter()]
        [ValidateSet('lsi', 'lsi53c810', 'virtio-scsi-pci', 'virtio-scsi-single', 'megasas', 'pvscsi')]
        [String]
        $SCSIController,

        [Parameter(HelpMessage ='Example: @{0 = "key1=value1,key2=value2,key3=value3"}. In the hashtable, the key is the Serial device ID; the value is the argument(s). Create a serial device inside the VM. Use with caution. Per the API documentation, a limit of 0 to 3 Serial devices can be speified. Refer to API documentation for argument formatting.')]
        [ValidateScript({
            $validationErrors = @()
            $_ | ForEach-Object {
                $key = $_.GetEnumerator().Name
                if ($key -match '\D') { $validationErrors += 'One or more hashtables contains a key that is not an integer.' }
                elseif ($key -lt 0 -or $key -gt 3) { $validationErrors += 'One ore more hashtables contains a key that is an integer outside the range of 0 to 3.'}
            }
            if ($validationErrors) { throw "The following error(s) occurred:`n$($validationErrors | Out-String)." }
            else { return $true }
        })]
        [Hashtable[]]
        $SerialDeviceOptions,

        [Parameter(HelpMessage = 'Amount of memory shares for auto-ballooning. The larger the number, the more memory the VM gets. Relative to weights of all other running VMs. 0 diasbles auto-ballooning.')]
        [ValidateRange(0,50000)]
        [Int]
        $AutoBallooningMemoryShares,

        [Parameter(HelpMessage = 'Specify SMBIOS type 1 parameters. Refer to API documentation for argument formatting.')]
        [ValidateNotNullOrEmpty()]
        [String]
        $SMBIOSType1Options,

        [Parameter()]
        [ValidateScript({ $_ -ge 1})]
        [Byte]
        $CPUSockets,

        [Parameter(HelpMessage = 'Example: foldersharing=1,videostreaming=filter. Refer to API documentation for argument formatting.')]
        [ValidateNotNullOrEmpty()]
        [String]
        $SPICEOptions,

        [Parameter(HelpMessage = 'cloud-init: Set pubic SSH keys. One key per line. OpenSSH format.')]
        [ValidateNotNullOrEmpty()]
        [String]
        $OpenSSHPublicKeys,

        [Parameter()]
        [Bool]
        $StartVMOnCreate,

        [Parameter(HelpMessage = 'Specify as YYYY-MM-DDTHH:mm:ss or YYYY-MM-DD')]
        [DateTime]
        $SetRealTimeClock,

        [Parameter(HelpMessage = 'Startup and Shutdown order. Refer to API documentation for argument formatting.')]
        [ValidateNotNullOrEmpty()]
        [String]
        $StartupShutdownOrder,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]
        $DefaultStorage,

        [Parameter(HelpMessage = 'Enable/Disable the USB tablet device. Usually needed to allow absolute mouse pointing with VNC clients. If running lots of console-only guest on one host, consider disabling.')]
        [Bool]
        $EnableUSBTablet,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]
        $Tags,

        [Parameter()]
        [Bool]
        $EnableTimeDriftFix,

        [Parameter()]
        [Bool]
        $ConvertToTemplate,

        [Parameter()]
        [Bool]
        $AssignUniqueEthernetAddress,

        [Parameter(HelpMessage ='Example: @{0 = "key1=value1,key2=value2,key3=value3"}. In the hashtable, the key is the USB device ID; the value is the argument(s). Configure USB device. Per the API documentation, a limit of 0 to 4 USB devices can be speified. Refer to API documentation for argument formatting.')]
        [ValidateScript({
            $validationErrors = @()
            $_ | ForEach-Object {
                $key = $_.GetEnumerator().Name
                if ($key -match '\D') { $validationErrors += 'One or more hashtables contains a key that is not an integer.' }
                elseif ($key -lt 0 -or $key -gt 3) { $validationErrors += 'One ore more hashtables contains a key that is an integer outside the range of 0 to 3.'}
            }
            if ($validationErrors) { throw "The following error(s) occurred:`n$($validationErrors | Out-String)." }
            else { return $true }
        })]
        [Hashtable[]]
        $USBDeviceOptions,

        [Parameter(HelpMessage = 'Number of hotplugged vCPUs.')]
        [Byte]
        $vCPU,

        [Parameter(HelpMessage = 'Configure VGA hardware. Refer to API documentation for argument formatting.')]
        [ValidateNotNullOrEmpty()]
        [String]
        $VGAOptions,

        [Parameter(HelpMessage ='Example: @{0 = "key1=value1,key2=value2,key3=value3"}. In the hashtable, the key is the VirtIO device ID; the value is the argument(s). Use a volume as an VirtIO hard disk. Per the API documentation, a limit of 0 to 15 VirtIO devices can be speified. Refer to API documentation for argument formatting.')]
        [ValidateScript({
            $validationErrors = @()
            $_ | ForEach-Object {
                $key = $_.GetEnumerator().Name
                if ($key -match '\D') { $validationErrors += 'One or more hashtables contains a key that is not an integer.' }
                elseif ($key -lt 0 -or $key -gt 15) { $validationErrors += 'One ore more hashtables contains a key that is an integer outside the range of 0 to 15.'}
            }
            if ($validationErrors) { throw "The following error(s) occurred:`n$($validationErrors | Out-String)." }
            else { return $true }
        })]
        [Hashtable[]]
        $VirtIOVolumeOptions,

        [Parameter(HelpMessage = 'VM generation ID. Exposes a 128-bit integer value identifier to the guest OS. This allows the guest OS to know when the VM is executed with a different configuration. Refer to the API documentation for more information.')]
        [ValidateNotNullOrEmpty()]
        [String]
        $VMGenerationID,

        [Parameter(HelpMessage = 'Default storage for VM state volumes/files.')]
        [ValidateNotNullOrEmpty()]
        [String]
        $VMStateStorage,

        [Parameter(HelpMessage = 'Create a virtual hardware watchdog device. Refer to API documentation for more information.')]
        [ValidateNotNullOrEmpty()]
        [String]
        $WatchdogDeviceOptions
    )
    begin{

        $body = @{}
        if ($PSBoundParameters['VMID']) { $body.Add('vmid', $PSBoundParameters['VMID']) }
        if ($PSBoundParameters['EnableACPI']) { $body.Add('acpi', $PSBoundParameters['EnableACPI']) }
        if ($PSBoundParameters['QEMUAgentOptions']) { $body.Add('agent', $PSBoundParameters['QEMUAgentOptions']) }
        if ($PSBoundParameters['Architecture']) { $body.Add('arch', $PSBoundParameters['Architecture']) }
        if ($PSBoundParameters['Archive']) { $body.Add('archive', $PSBoundParameters['Archive']) }
        if ($PSBoundParameters['KVMArguments']) { $body.Add('args', $PSBoundParameters['KVMArguments']) }
        if ($PSBoundParameters['ConfigureAudioDevice']) { $body.Add('audio0', $PSBoundParameters['ConfigureAudioDevice']) }
        if ($PSBoundParameters['BalloonMemMB']) { $body.Add('balloon', $PSBoundParameters['BalloonMemMB']) }
        if ($PSBoundParameters['BIOS']) { $body.Add('bios', $PSBoundParameters['BIOS']) }
        if ($PSBoundParameters['VMBootOrder']) { $body.Add('boot', $PSBoundParameters['VMBootOrder']) }
        if ($PSBoundParameters['BandwithLimitKiBs']) { $body.Add('bwlimit', $PSBoundParameters['BandwithLimitKiBs']) }
        if ($PSBoundParameters['CloudInitCustomFile']) { $body.Add('cicustom', $PSBoundParameters['CloudInitCustomFile']) }
        if ($PSBoundParameters['CloudInitPassword']) {
            try {
                $body.Add('cipassword', ($PSBoundParameters['CloudInitPassword'] | Read-SecureString))
            }
            catch {
                throw "Error reading SecureString from parameter CloudInitPassword:`n$_"
            }
        }
        if ($PSBoundParameters['CloudInitType']) { $body.Add('citype', $PSBoundParameters['CloudInitType']) }
        if ($PSBoundParameters['CloudInitUser']) { $body.Add('ciuser', $PSBoundParameters['CloudInitUser']) }
        if ($PSBoundParameters['CoresPerSocket']) { $body.Add('cores', $PSBoundParameters['CoresPerSocket']) }
        if ($PSBoundParameters['CPUType']) { $body.Add('cpu', $PSBoundParameters['CPUType']) }
        if ($PSBoundParameters['CPULimit']) { $body.Add('cpulimit', $PSBoundParameters['CPULimit']) }
        if ($PSBoundParameters['CPUPriority']) { $body.Add('cpuunits', $PSBoundParameters['CPUPriority']) }
        if ($PSBoundParameters['VMDescription']) { $body.Add('description', $PSBoundParameters['VMDescription']) }
        if ($PSBoundParameters['EFIDisk']) { $body.Add('efidisk0', $PSBoundParameters['EFIDisk']) }
        if ($PSBoundParameters['Force']) { $body.Add('force', $PSBoundParameters['Force']) }
        if ($PSBoundParameters['FreezeCPU']) { $body.Add('freeze', $PSBoundParameters['FreezeCPU']) }
        if ($PSBoundParameters['HookScript']) { $body.Add('hookscript', $PSBoundParameters['HookScript']) }
        if ($PSBoundParameters['MapHostPCIDevices']) {
            $PSBoundParameters['MapHostPCIDevices'].GetEnumerator() | ForEach-Object {
                $hashtable = $_
                $body.Add("hostpci[$($hashtable.Keys)]", $hashtable.Values) # Format should be that of param[n]=key1=value1,key2=value2
            }
        }
        if ($PSBoundParameters['HotPlugFeatures']) { $body.Add('hotplug', $PSBoundParameters['HotPlugFeatures']) }
        if ($PSBoundParameters['MemoryHugePagesOption']) { $body.Add('hugepages', $PSBoundParameters['MemoryHugePagesOption']) }
        if ($PSBoundParameters['IDEVolumeOptions']) {
            $PSBoundParameters['IDEVolumeOptions'].GetEnumerator() | ForEach-Object {
                $hashtable = $_
                $body.Add("ide[$($hashtable.Keys)]", $hashtable.Values) # Format should be that of param[n]=key1=value1,key2=value2
            }
        }
        if ($PSBoundParameters['IPConfig']) {
            $PSBoundParameters['IPConfig'].GetEnumerator() | ForEach-Object {
                $hashtable = $_
                $body.Add("ipconfig[$($hashtable.Keys)]", $hashtable.Values) # Format should be that of param[n]=key1=value1,key2=value2
            }
        }
        if ($PSBoundParameters['InterVMSharedMemory']) { $body.Add('ivshmem', $PSBoundParameters['InterVMSharedMemory']) }
        if ($PSBoundParameters['PersistHugePages']) { $body.Add('keephugepages', $PSBoundParameters['PersistHugePages']) }
        if ($PSBoundParameters['VNCKeyboardLayout']) { $body.Add('keyboard', $PSBoundParameters['VNCKeyboardLayout']) }
        if ($PSBoundParameters['EnableKVMHardwarVirtualization']) { $body.Add('kvm', $PSBoundParameters['EnableKVMHardwarVirtualization']) }
        if ($PSBoundParameters['SetRealClockToLocalTime']) { $body.Add('localtime', $PSBoundParameters['SetRealClockToLocalTime']) }
        if ($PSBoundParameters['VMLockType']) { $body.Add('lock', $PSBoundParameters['VMLockType']) }
        if ($PSBoundParameters['QEMUMachineType']) { $body.Add('machine', $PSBoundParameters['QEMUMachineType']) }
        if ($PSBoundParameters['VMMemoryMB']) { $body.Add('memory', $PSBoundParameters['VMMemoryMB']) }
        if ($PSBoundParameters['MaxMigrationDownTimeSeconds']) { $body.Add('migrate_downtime', $PSBoundParameters['MaxMigrationDownTimeSeconds']) }
        if ($PSBoundParameters['MigrationSpeedLimitMBs']) { $body.Add('migrate_speed', $PSBoundParameters['MigrationSpeedLimitMBs']) }
        if ($PSBoundParameters['VMName']) { $body.Add('name', $PSBoundParameters['VMName']) }
        if ($PSBoundParameters['NameServer']) { $body.Add('nameserver', $PSBoundParameters['NameServer']) }
        if ($PSBoundParameters['ConfigureNetworkDevice']) {
            $PSBoundParameters['ConfigureNetworkDevice'].GetEnumerator() | ForEach-Object {
                $hashtable = $_
                $body.Add("net[$($hashtable.Keys)]", $hashtable.Values) # Format should be that of param[n]=key1=value1,key2=value2
            }
        }
        if ($PSBoundParameters['EnableNUMA']) { $body.Add('numa', $PSBoundParameters['EnableNUMA']) }
        if ($PSBoundParameters['ConfigureNUMATopology']) {
            $PSBoundParameters['ConfigureNUMATopology'].GetEnumerator() | ForEach-Object {
                $hashtable = $_
                $body.Add("numa[$($hashtable.Keys)]", $hashtable.Values) # Format should be that of param[n]=key1=value1,key2=value2
            }
        }
        if ($PSBoundParameters['StartVMAtSystemBoot']) { $body.Add('onboot', $PSBoundParameters['StartVMAtSystemBoot']) }
        if ($PSBoundParameters['GuestOSType']) { $body.Add('ostype', $PSBoundParameters['GuestOSType']) }
        if ($PSBoundParameters['MapHostParallelDevices']) {
            $PSBoundParameters['MapHostParallelDevices'].GetEnumerator() | ForEach-Object {
                $hashtable = $_
                $body.Add("parallel[$($hashtable.Keys)]", $hashtable.Values) # Format should be that of param[n]=key1=value1,key2=value2
            }
        }
        if ($PSBoundParameters['AddToPool']) { $body.Add('pool', $PSBoundParameters['AddToPool']) }
        if ($PSBoundParameters['ProtectVM']) { $body.Add('protection', $PSBoundParameters['ProtectVM']) }
        if ($PSBoundParameters['CloseShellOnReboot']) { $body.Add('reboot', $PSBoundParameters['CloseShellOnReboot']) }
        if ($PSBoundParameters['VirtIORandomNumberGenerator']) { $body.Add('rng0', $PSBoundParameters['VirtIORandomNumberGenerator']) }
        if ($PSBoundParameters['SATAVolumeOptions']) {
            $PSBoundParameters['SATAVolumeOptions'].GetEnumerator() | ForEach-Object {
                $hashtable = $_
                $body.Add("sata[$($hashtable.Keys)]", $hashtable.Values) # Format should be that of param[n]=key1=value1,key2=value2
            }
        }
        if ($PSBoundParameters['SCSIVolumeOptions']) {
            $PSBoundParameters['SCSIVolumeOptions'].GetEnumerator() | ForEach-Object {
                $hashtable = $_
                $body.Add("scsi[$($hashtable.Keys)]", $hashtable.Values) # Format should be that of param[n]=key1=value1,key2=value2
            }
        }
        if ($PSBoundParameters['SCSIController']) { $body.Add('scsihw', $PSBoundParameters['SCSIController']) }
        if ($PSBoundParameters['SerialDeviceOptions']) {
            $PSBoundParameters['SerialDeviceOptions'].GetEnumerator() | ForEach-Object {
                $hashtable = $_
                $body.Add("serial[$($hashtable.Keys)]", $hashtable.Values) # Format should be that of param[n]=key1=value1,key2=value2
            }
        }
        if ($PSBoundParameters['AutoBallooningMemoryShares']) { $body.Add('shares', $PSBoundParameters['AutoBallooningMemoryShares']) }
        if ($PSBoundParameters['SMBIOSType1Options']) { $body.Add('smbios1', $PSBoundParameters['SMBIOSType1Options']) }
        if ($PSBoundParameters['CPUSockets']) { $body.Add('sockets', $PSBoundParameters['CPUSockets']) }
        if ($PSBoundParameters['SPICEOptions']) { $body.Add('spice_enhancements', $PSBoundParameters['SPICEOptions']) }
        if ($PSBoundParameters['OpenSSHPublicKeys']) { $body.Add('sshkeys', $PSBoundParameters['OpenSSHPublicKeys']) }
        if ($PSBoundParameters['StartVMOnCreate']) { $body.Add('start', $PSBoundParameters['StartVMOnCreate']) }
        if ($PSBoundParameters['SetRealTimeClock']) { $body.Add('startdate', $PSBoundParameters['SetRealTimeClock']) }
        if ($PSBoundParameters['StartupShutdownOrder']) { $body.Add('startup', $PSBoundParameters['StartupShutdownOrder']) }
        if ($PSBoundParameters['DefaultStorage']) { $body.Add('storage', $PSBoundParameters['DefaultStorage']) }
        if ($PSBoundParameters['EnableUSBTablet']) { $body.Add('tablet', $PSBoundParameters['EnableUSBTablet']) }
        if ($PSBoundParameters['Tags']) { $body.Add('tags', $PSBoundParameters['Tags']) }
        if ($PSBoundParameters['EnableTimeDriftFix']) { $body.Add('tdf', $PSBoundParameters['EnableTimeDriftFix']) }
        if ($PSBoundParameters['ConvertToTemplate']) { $body.Add('template', $PSBoundParameters['ConvertToTemplate']) }
        if ($PSBoundParameters['AssignUniqueEthernetAddress']) { $body.Add('unique', $PSBoundParameters['AssignUniqueEthernetAddress']) }
        if ($PSBoundParameters['SCSIController']) { $body.Add('scsihw', $PSBoundParameters['SCSIController']) }
        if ($PSBoundParameters['USBDeviceOptions']) {
            $PSBoundParameters['USBDeviceOptions'].GetEnumerator() | ForEach-Object {
                $hashtable = $_
                $body.Add("usb[$($hashtable.Keys)]", $hashtable.Values) # Format should be that of param[n]=key1=value1,key2=value2
            }
        }
        if ($PSBoundParameters['vCPU']) { $body.Add('vcpus', $PSBoundParameters['vCPU']) }
        if ($PSBoundParameters['VGAOptions']) { $body.Add('vga', $PSBoundParameters['VGAOptions']) }
        if ($PSBoundParameters['VirtIOVolumeOptions']) {
            $PSBoundParameters['VirtIOVolumeOptions'].GetEnumerator() | ForEach-Object {
                $hashtable = $_
                $body.Add("virtio[$($hashtable.Keys)]", $hashtable.Values) # Format should be that of param[n]=key1=value1,key2=value2
            }
        }
        if ($PSBoundParameters['VMGenerationID']) { $body.Add('vmgenid', $PSBoundParameters['VMGenerationID']) }
        if ($PSBoundParameters['VMStateStorage']) { $body.Add('vmstatestorage', $PSBoundParameters['VMStateStorage']) }
        if ($PSBoundParameters['WatchdogDeviceOptions']) { $body.Add('watchdog', $PSBoundParameters['WatchdogDeviceOptions']) }

    }
    process {

        $ProxmoxNode | ForEach-Object {

            $node = $_
            try {
                Send-PveApiRequest -Method Post -Uri ($ProxmoxApiBaseUri.AbsoluteUri + "nodes/$($node.node)/qemu") -Body $body |
                Select-Object -ExpandProperty data
            }
            catch {
                Write-Error -Exception $_.Exception
            }

        }

    }

}