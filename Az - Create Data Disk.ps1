$datadisklist = Import-Csv -Path "C:\Users\digiorgiot\OneDrive - Version 1\Customers\SIA\ScriptFinal\vmdatadisk_SQL.csv"
$lun = 0
$location = "uksouth"
foreach($disk in $datadisklist){
        $diskname = "$($disk.vmname)-DataDisk-$lun"
        $datadisk = Get-AzDisk -ResourceGroupName $disk.vmrg -DiskName $diskname -ErrorAction SilentlyContinue
        if(!$datadisk){            
            $diskConfig = New-AzDiskConfig -AccountType $disk.accounttype -Location $location -CreateOption Empty -DiskSizeGB $disk.size
            $datadisk = New-AzDisk -Disk $diskConfig -ResourceGroupName $disk.vmrg -DiskName $diskname
        }
        $vm = Get-AzVM -ResourceGroupName $disk.vmrg -Name $disk.vmname
        Add-AzVMDataDisk -CreateOption Attach -Lun $lun -VM $vm -ManagedDiskId $datadisk.Id
        Update-AzVM -VM $vm -ResourceGroupName $vm.ResourceGroupName
        $lun = $lun + 1
}