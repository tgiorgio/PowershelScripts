param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$DNSservers
)

$nic = Get-NetIPAddress -InterfaceAlias "Ethernet" -AddressFamily IPv4
$gatewayIP = (Get-NetIPConfiguration -InterfaceAlias $nic.InterfaceAlias).IPv4DefaultGateway.nexthop

$ipTransform = $gatewayIP.split('.')
$ipTransform[-1] = 1
$gatewayNEWip = $ipTransform -join '.'

#$dns =  Get-DnsClientServerAddress -InterfaceAlias $nic.InterfaceAlias -AddressFamily IPv4


Remove-NetIPAddress -InterfaceAlias $nic.InterfaceAlias -Confirm:$false
New-NetIPAddress -IPAddress $nic.IPAddress -PrefixLength $nic.PrefixLength -InterfaceAlias $nic.InterfaceAlias -Confirm:$false

Remove-NetRoute -InterfaceAlias $nic.InterfaceAlias -Confirm:$false
New-NetRoute -InterfaceAlias $nic.InterfaceAlias -NextHop $gatewayNEWip -DestinationPrefix 0.0.0.0/0 -Confirm:$false


Set-DnsClientServerAddress -InterfaceAlias $nic.InterfaceAlias -ServerAddresses $DNSservers -Confirm:$false