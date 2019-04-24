$fileUri = @("https://siadevbootdiagstorage.blob.core.windows.net/serverconfigscripts/Windows-InstallOPSViewAgent.ps1",
"https://siadevbootdiagstorage.blob.core.windows.net/serverconfigscripts/Opsview_Windows_Agent_x64_24-09-18-1500.msi")

$Settings = @{"fileUris" = $fileUri;"timestamp"= 10};

$storageaccname = "siadevbootdiagstorage"
$storagekey = "FfAI5/O+t7kOesXfr8yU3a4kOvXM/lq+XQVnYcs4yzsLZ3xqFbL01K4S8NymqrCkZ1LUqB4FHEpd4ADw5IHI+A=="
$ProtectedSettings = @{"storageAccountName" = $storageaccname; "storageAccountKey" = $storagekey; "commandToExecute" = "powershell -ExecutionPolicy Unrestricted -File Windows-InstallOPSViewAgent.ps1 -trustedHosts 10.200.10.10"};


#run command
$internalVMs = get-azvm |?{($_.name -match "siaistdb01") -and ($_.StorageProfile.OsDisk.OsType -eq "Windows")}
foreach($vm in $internalVMs){
    Set-AzVMExtension -ResourceGroupName $vm.ResourceGroupName -Location $vm.location -VMName $vm.name -Name "ServerSetup" -Publisher "Microsoft.Compute" -ExtensionType "CustomScriptExtension" -TypeHandlerVersion "1.9" -Settings $Settings -ProtectedSettings $ProtectedSettings -AsJob
}