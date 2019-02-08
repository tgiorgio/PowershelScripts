$fileUri = @("https://siadevbootdiagstorage.blob.core.windows.net/serverconfigscripts/Windows-CheckNetworkConfig.ps1")

$Settings = @{"fileUris" = $fileUri};

$storageaccname = "siadevbootdiagstorage"
$storagekey = "PraqUeGeK2Bz4Vq0xBw6AIOhd1545GtQ8wgU9aJvgaoQDNiweSei1cV89DEOtlhQI5a+17zD55ZSGtWmJCTT7A=="
$ProtectedSettings = @{"storageAccountName" = $storageaccname; "storageAccountKey" = $storagekey; "commandToExecute" = "powershell -ExecutionPolicy Unrestricted -File Windows-CheckNetworkConfig.ps1"};

#run command
Set-AzureRmVMExtension -ResourceGroupName siaistdb_rg -Location uksouth -VMName siaistdb01 -Name "TestScript2" -Publisher "Microsoft.Compute" -ExtensionType "CustomScriptExtension" -TypeHandlerVersion "1.9" -Settings $Settings -ProtectedSettings $ProtectedSettings