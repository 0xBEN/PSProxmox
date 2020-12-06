# Add class ProxmoxNode for parameter validation
class ProxmoxNode {
   [String]$node
   [String]$status
   [Decimal]$cpu
   [String]$level
   [Byte]$maxcpu
   [Long]$maxmem
   [Long]$mem
   [String]$ssl_fingerprint
   [Int]$uptime
}

# Add class ProxmoxContainer for parameter validation
class ProxmoxContainer {
   [ProxmoxNode]$node
   [Int]$cpu
   [Int]$cpus
   [Int]$disk
   [Int]$diskread
   [Int]$diskwrite
   [String]$lock
   [Long]$maxdisk
   [Long]$maxmem
   [Int]$maxswap
   [Int]$mem
   [String]$name
   [Long]$netin
   [Long]$netout
   [String]$status
   [Int]$swap
   [String]$template
   [String]$type
   [Int]$uptime
   [String]$vmid
}

# Add class ProxmoxVM for parameter validation
class ProxmoxVM {
   [ProxmoxNode]$node
   [Decimal]$cpu
   [Int]$cpus
   [Int]$disk
   [Int]$diskread
   [Int]$diskwrite
   [Long]$maxdisk
   [Long]$maxmem
   [Long]$mem
   [String]$name
   [Long]$netin
   [Long]$netout
   [String]$pid
   [String]$status
   [String]$template
   [Int]$uptime
   [String]$vmid
}