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
if($domainJoin -eq "Siadevexternal.net"){
    msiexec.exe /qn /l* log.txt /i Opsview_Windows_Agent_x64_24-09-18-1500.msi ALLOWED_HOSTS=10.200.110.10
}else{
    msiexec.exe /qn /l* log.txt /i Opsview_Windows_Agent_x64_24-09-18-1500.msi ALLOWED_HOSTS=10.200.10.10
}
&.\Windows-JoinDomain.ps1 -domainname $domainJoin -username "$domainJoin\domain.join" -userpassword "4#bSJAw#Xr354cq%"
Stop-Transcript