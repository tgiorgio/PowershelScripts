$rgName = 'LIVE-JUMPBOX';
 $vmName = 'EUNLIVEWJMP01';
 $KeyVaultName = 'Oir-LIVE-KeyVault';
 $KeyVault = Get-AzKeyVault -VaultName $KeyVaultName -ResourceGroupName "LIVE-KeyVault";
 $diskEncryptionKeyVaultUrl = $KeyVault.VaultUri;
 $KeyVaultResourceId = $KeyVault.ResourceId;

 Set-azurermVMDiskEncryptionExtension -ResourceGroupName $rgname -VMName $vmName -DiskEncryptionKeyVaultUrl $diskEncryptionKeyVaultUrl -DiskEncryptionKeyVaultId $KeyVaultResourceId;    