#$fileUri = @("\\10.100.10.15\configurationscripts\Windows-FormatDataDisk.ps1",
#"\\10.100.10.15\configurationscripts\Windows-InstallFeature-IIS.ps1",
#"\\10.100.10.15\configurationscripts\Windows-InstallFeature-SNMP.ps1",
#"\\10.100.10.15\configurationscripts\Windows-AzureMasterScript.ps1")
#"https://siaprdstorconfigscript01.blob.core.windows.net/configscripts/Windows-FormatDataDisk.ps1",
#"https://siaprdstorconfigscript01.blob.core.windows.net/configscripts/Windows-InstallFeature-SNMP.ps1")

#$Settings = @{"fileUris" = $fileUri;"timestamp"= 22};
$Settings = @{"timestamp"= 45};

#$storageaccname = "siaprdstorconfigscript01"
#$storagekey = "4TnWscmrsVhSfDJuy9equlKQViYQiAJ3gILoYmKpAgsM5JMVf+qlv0eNPHyACsIge1nYXLV9Mt/Unww1vNxysA=="
$ProtectedSettings = @{"storageAccountName" = $storageaccname; "storageAccountKey" = $storagekey; "commandToExecute" = "powershell Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False"};

#run command
$internalVMs = get-azvm |?{($_.name -match "siaept") -and ($_.StorageProfile.OsDisk.OsType -eq "Windows")}

#$internalVMs = Import-Csv -Path "C:\Users\digiorgiot\OneDrive - Version 1\Customers\SIA\Production\vmtocreateSysSmtp.csv"
foreach($vm in $internalVMs){
    #Remove-AzVMExtension -ResourceGroupName $vm.ResourceGroupName -VMName $vm.name -Name "AzureDiskEncryption" -Force
    
    if ($vm.name -notmatch "siaiprdad"){
        Write-Host $vm.name -ForegroundColor Green
        Set-AzVMExtension -ResourceGroupName $vm.ResourceGroupName -Location $vm.location -VMName $vm.name -Name "ServerSetup" -Publisher "Microsoft.Compute" -ExtensionType "CustomScriptExtension" -TypeHandlerVersion "1.9" -Settings $Settings -ProtectedSettings $ProtectedSettings -AsJob
    }
    #>
}
