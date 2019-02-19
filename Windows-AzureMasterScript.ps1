param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$domainJoin
)
Start-Transcript .\powershell.log

if($domainJoin -eq "Siadevexternal.net"){
    &.\Windows-ChangeIPConfig.ps1 -DNSservers "10.200.111.10,10.200.111.11"
}else{
    &.\Windows-ChangeIPConfig.ps1 -DNSservers "10.200.11.10,10.200.11.11"
}

&.\Windows-InstallFeature-IIS.ps1
&.\Windows-InstallFeature-SNMP.ps1
&.\Windows-FormatDataDisk.ps1
&.\Windows-JoinDomain.ps1 -domainname $domainJoin -username "$domainJoin\domain.join" -userpassword "4#bSJAw#Xr354cq%"
Stop-Transcript