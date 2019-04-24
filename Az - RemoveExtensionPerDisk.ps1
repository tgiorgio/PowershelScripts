$noEncrypt = Get-AzDisk | ?{($_.EncryptionSettings -eq $null)-and($_.ManagedBy -notmatch "gate")-and($_.ManagedBy -notmatch "web")-and ($_.ManagedBy -ne $null)}
$vms = @()
foreach($disk in $noEncrypt){
    $name = [string]$disk.managedby
    $name2 = $name.substring($name.LastIndexOf('/')+1)
    
    $vms += New-Object -TypeName psobject -Property @{VMname=$name2;ResourceGroup = $disk.ResourceGroupName}
}

foreach ($vm in $vms){
    Remove-AzVMExtension -ResourceGroupName $vm.ResourceGroup -VMName $vm.VMname -Name "AzureDiskEncryption" -Force
}

