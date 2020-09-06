# Add class ProxmoxNode for parameter validation
Add-Type @"
public struct ProxmoxNode {
   public string node;
   public string status;
   public decimal cpu;
   public string level;
   public byte maxcpu;
   public long maxmem;
   public long mem;
   public string ssl_fingerprint;
   public int uptime;
}
"@