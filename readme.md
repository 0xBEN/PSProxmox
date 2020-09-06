# PSProxmox
A PowerShell module for interfacing with the Proxmox JSON API

## Module Design
```
PSProxmox/
|___Classes/ps1/
|___Public/ps1/
|___Private/ps1/
PSProxmox.psd1
PSProxmox.psm1
```
In `Public/ps1/` are all of the public functions that are executable to the user.

In `Private/ps1/` are all of the private functions that the user should not run. These functions serve the primary purpose of helper functions. 

In `Classes/ps1/` are all of the custom class types for use in this module as a way to validate pipeline object input.

Each function gets its own `.ps1` file. By doing so, the code is lean, easier to debug, transparent, and modular.

If you look at the `.psm1` script module file, you will see how this file orchestrates the updating of the module manifest and the exporting of **public** functions.

## Naming Scheme
All functions use PowerShell-approved verbs following the Proxmox API endpoint contexts:
- **Cluster** (aka Datacenter): Example `Get-ProxmoxDataCenterLog`
- **Node** (a server in a cluster): Example `Open-ProxmoxNodeSpiceProxy`
- A few exceptions for certain API endpoints, but the naming is clear in the function: Example `Get-ProxmoxUser`

## Orchestrating I/O
Where applicable, functions are designed to take **pipeline input** of an **object**.
```powershell
Param (
    [Parameter(
        Mandatory = $true,
        Position = 0,
        ValueFromPipeline = $true
    )]
    [ProxmoxNode[]]
    $ProxmoxNode
)
```
Using `Get-ProxmoxNodeVM` as an example, this function takes the mandatory parameter `-ProxmoxNode` explicitly or as pipeline input. Effectively you could execute this function in the following ways:
- `Get-ProxmoxNode | Where-Object {$_.node -eq 'NodeName'} | Get-ProxmoxNodeVM`
- `$node | Get-ProxmoxNodeVM`
- `Get-ProxmoxNodeVM -ProxmoxNode $node`
