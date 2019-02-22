$rgName = 'siaedevops_rg';
$vmName = 'siaedevops01';
$KeyVaultName = 'siadevencrypt';
$KeyVault = Get-AzKeyVault -VaultName $KeyVaultName -ResourceGroupName "siadevencrypt-rg";
$diskEncryptionKeyVaultUrl = $KeyVault.VaultUri;
$KeyVaultResourceId = $KeyVault.ResourceId;

$AADClientName = "EncryptionApp"
$AADClientSecret = "5T7OKpb/3mY2JojlYkQqYh4mgzUkhB2b9gFlG5Td3oc="

$SvcPrincipals = (Get-AzADServicePrincipal -SearchString $AADClientName)
$AADClientID = $SvcPrincipals.ApplicationId

#To encryption WITHOUT azure AD Web Application
 Set-AzVMDiskEncryptionExtension -ResourceGroupName $rgname -VMName $vmName -DiskEncryptionKeyVaultUrl $diskEncryptionKeyVaultUrl -DiskEncryptionKeyVaultId $KeyVaultResourceId;    

 #To encryption WITH azure AD Web Application
 Set-AzVMDiskEncryptionExtension -ResourceGroupName $rgName -VMName $vmName -AadClientID $AADClientID -AadClientSecret $AADClientSecret -DiskEncryptionKeyVaultUrl $diskEncryptionKeyVaultUrl -DiskEncryptionKeyVaultId $KeyVaultResourceId -VolumeType 'All' -SkipVmBackup -Confirm:$false -Force -ErrorAction Continue