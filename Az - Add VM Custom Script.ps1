$fileUri = @("https://siadevbootdiagstorage.blob.core.windows.net/serverconfigscripts/Windows-AzureMasterScript.ps1",
"https://siadevbootdiagstorage.blob.core.windows.net/serverconfigscripts/Windows-ChangeIPConfig.ps1",
"https://siadevbootdiagstorage.blob.core.windows.net/serverconfigscripts/Windows-InstallFeature-IIS.ps1",
"https://siadevbootdiagstorage.blob.core.windows.net/serverconfigscripts/Windows-InstallFeature-SNMP.ps1",
"https://siadevbootdiagstorage.blob.core.windows.net/serverconfigscripts/Windows-JoinDomain.ps1",
"https://siadevbootdiagstorage.blob.core.windows.net/serverconfigscripts/Windows-FormatDataDisk.ps1")

$Settings = @{"fileUris" = $fileUri;"timestamp"= 1};

$storageaccname = "siadevbootdiagstorage"
$storagekey = ""
$ProtectedSettings = @{"storageAccountName" = $storageaccname; "storageAccountKey" = $storagekey; "commandToExecute" = "powershell -ExecutionPolicy Unrestricted -File Windows-AzureMasterScript.ps1 -DomainJoin siadevexternal.net"};
$resourcegroupname = "siaeptws_rg"
$vmname = "siaeptws01"
$location ="uksouth"

#run command
Set-AzVMExtension -ResourceGroupName $resourcegroupname -Location $location -VMName $vmname -Name "ServerSetup" -Publisher "Microsoft.Compute" -ExtensionType "CustomScriptExtension" -TypeHandlerVersion "1.9" -Settings $Settings -ProtectedSettings $ProtectedSettings
