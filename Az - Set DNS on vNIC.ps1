
$vms = get-azvm |?{( ($_.name -match "siaelst") -and ($_.StorageProfile.OsDisk.OsType -eq "Windows"))}

foreach($vm in $vms){
    write-host $vm.Name
    
    
    $nicname = "$($vm.name)-NIC"
    $nic = Get-AzNetworkInterface -Name $nicname -ResourceGroupName $vm.ResourceGroupName -ErrorAction SilentlyContinue
    if($nic){
        $nic.DnsSettings.DnsServers.Remove("168.63.129.16")
        $nic.DnsSettings.DnsServers.Add("10.100.111.10")
        $nic.DnsSettings.DnsServers.Add("10.100.111.11")
        
        $tes = $nic | Set-AzNetworkInterface 
        write-host "Succesfully added the DNS to the Network Interface of server $($vm.name)" -ForegroundColor Green
        Restart-AzVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.name -AsJob
    }else{
        write-host "Skipped $($vm.name)" -ForegroundColor Red
    }
    #>
}

