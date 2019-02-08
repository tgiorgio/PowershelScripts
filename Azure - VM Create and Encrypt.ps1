<#
Author: Thiago Di Giorgio
Email: thiago.gio@hotmail.com

Infrastructure Pre-requisites
	1. Network previously created
	2. Availability sets previously created on the same RG as the VMs
    3. KeyVault for encryption already created
    4. Azure AD global 

Assumptions
All Microsoft products image will run on Windows. E.g. SQL Server or BizTalk

Instructions
The script can create and encrypt Virtual Machines. It will read a CSV file where the VM parameters are. It has to be filled in correctly. 
There's an example provided with the script. It uses Azure AD Application to encrypt VMs. You can create the Azure AD APP manually or let the script do.
You have to be Global Admin in Azure AD in order to get it created. 
If you need data disks attached to the VMs you have to fill in the data disk parameter in the VMs csv with a Y
and use a second CSV with details about them, and also fill in correctly. An example is provided with this script.

Creation and encryption are done using jobs, so the script does not wait until the first creation/encryption finishes before proceeding.
Use Get-Job on the same PowerShell session to see status. There's a loop that waits until all jobs are completed and won't 
go to encryption if one of the jobs fail. In this case you have to stop the script after all jobs completed, either successfully or 
failed, and investigate. Then you can run the script again, it will skip existent VMs.

The script automatically enable ARM resource lock on KeyVault to prevent accidental key vault deletion. If this is not desired this part has to be commented.


#>
#Requires -Module AzureRM.Resources
#Requires -Module AzureRM.KeyVault
Param(
  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]$csvpath,

  [Parameter(Mandatory = $false,
            HelpMessage="Name of the KeyVault in which encryption keys are to be placed. A new vault with this name will be created if one doesn't exist")]
  [ValidateNotNullOrEmpty()]
  [string]$keyVaultName,


  [Parameter(Mandatory = $false, 
             HelpMessage="Name of the resource group to which the KeyVault belongs to.  A new resource group with this name will be created if one doesn't exist")]
  [ValidateNotNullOrEmpty()]
  [string]$KeyVaultRGName,

  [Parameter(Mandatory = $false,
             HelpMessage="Name of the AAD application that will be used to write secrets to KeyVault. A new application with this name will be created if one doesn't exist. If this app already exists, pass aadClientSecret parameter to the script")]
  [ValidateNotNullOrEmpty()]
  [string]$aadAppName,

  [Parameter(Mandatory = $false,
             HelpMessage="Client secret of the AAD application that was created earlier")]
  [ValidateNotNullOrEmpty()]
  [string]$aadClientSecret,

  [Parameter(Mandatory = $false)]
  [ValidateNotNullOrEmpty()]
  [string]$datadiskcsvpath,

  [Parameter(Mandatory = $false)]
  [ValidateNotNullOrEmpty()]
  [string]$tagscsvpath

)


#####
#Script Logs all to the current directory
$CurrentDir = $(get-location).Path;
Start-Transcript -Path "$CurrentDir\Azure-PowershellLog.txt"




####################################################################################################################################
# Section1:  Create all VMs from the CSV.
####################################################################################################################################

#Importing all CSV files into variables for later use
$vmlist = Import-Csv -Path $csvpath
if($datadiskcsvpath -ne ""){
    $datadisklist = Import-Csv -Path $datadiskcsvpath
}
if($tagscsvpath -ne ""){
    $taglist = Import-Csv -Path $tagscsvpath 
}
foreach ($vm in $vmlist){ 

$resourceGroupName = $vm.ResourceGroupName
$location = $vm.location
$vmName = $vm.vmName
$userCredUsername = $vm.VMUsername
$userCredPassword = $vm.VMPassword
$vnetname = $vm.vnetName
$vnetRG = $vm.vnetRG
$subnetname = $vm.Subnetname
$nicname = $vm.nic
$publisher = $vm.OSPublisher
$offer = $vm.OSOffer
$sku = $vm.OSSKU
$vmsize = $vm.VMSize
$enableVMBootLog = $vm.BootDiagnostics # Y or N
$stgAccount = $vm.StorageAccountName
$stgAccountRG = $vm.StorageAccountRG
$availSetName = $vm.AvailabilitySetName
$vmdisktype = $vm.vmdisktype
$datadiskpresent = $vm.datadiskrequired # Y or N
$ipaddress = $vm.ip

$vmInstance = Get-AzureRmVM -ResourceGroupName $resourceGroupName -Name $vmname -ErrorAction SilentlyContinue


if(!$vmInstance){
Write-Host "Creating VM $($VM.vmname)" -ForegroundColor Green
$securepassword = ConvertTo-SecureString $userCredPassword -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ($userCredUsername,$securepassword)

$vnet = Get-AzureRmVirtualNetwork -Name $vnetname -ResourceGroupName $vnetRG #changes to this command
$subnet = $vnet.Subnets | Where-Object {$_.Name -eq $subnetname }

if(!$nicname){
    $nicname = "$vmName-NIC"
}

$nic = Get-AzureRmNetworkInterface -Name $nicname -ResourceGroupName $resourceGroupName -ErrorAction SilentlyContinue
if(!$nic){
    try {
        $nic = New-AzureRmNetworkInterface -Name "$vmName-NIC" -ResourceGroupName $resourceGroupName -Location $location -SubnetId $subnet.id -IpConfigurationName "$vmname-IP" -ErrorAction Stop

        if ($ipaddress){
            Set-AzureRmNetworkInterfaceIpConfig -NetworkInterface $nic -Name "$vmname-IP" -PrivateIpAddress $ipaddress -Subnet $subnet -Primary

            Set-AzureRmNetworkInterface -NetworkInterface $nic #showing things on screen
        }
    }
    catch {
        Write-Host "Error creating VNIC" -ForegroundColor Red
    }
}

if($availSetName){
    $availSet = Get-AzureRmAvailabilitySet -ResourceGroupName $resourceGroupName -Name $availSetName

    if($offer -match "Windows"){
        $vmconfig = New-AzureRmVMConfig -VMName $vmName -VMSize $vmsize -AvailabilitySetId $availSet.id| Set-AzureRmVMOperatingSystem -Windows -ComputerName $vmName -Credential $cred | Set-AzureRmVMSourceImage -PublisherName $publisher -Offer $Offer -Skus $sku -Version Latest | Add-AzureRmVMNetworkInterface -Id $nic.Id
    }else{
        $vmconfig = New-AzureRmVMConfig -VMName $vmName -VMSize $vmsize -AvailabilitySetId $availSet.id | Set-AzureRmVMOperatingSystem -Linux -ComputerName $vmName -Credential $cred | Set-AzureRmVMSourceImage -PublisherName $publisher -Offer $offer -Skus $sku -Version Latest | Add-AzureRmVMNetworkInterface -Id $nic.Id
    }
}else{
    if($publisher -match "microsoft"){
        $vmconfig = New-AzureRmVMConfig -VMName $vmName -VMSize $vmsize | Set-AzureRmVMOperatingSystem -Windows -ComputerName $vmName -Credential $cred | Set-AzureRmVMSourceImage -PublisherName $publisher -Offer $Offer -Skus $sku -Version Latest | Add-AzureRmVMNetworkInterface -Id $nic.Id
    }else{
        $vmconfig = New-AzureRmVMConfig -VMName $vmName -VMSize $vmsize | Set-AzureRmVMOperatingSystem -Linux -ComputerName $vmName -Credential $cred | Set-AzureRmVMSourceImage -PublisherName $publisher -Offer $offer -Skus $sku -Version Latest | Add-AzureRmVMNetworkInterface -Id $nic.Id
    }
}

if($publisher -match "microsoft"){
    $vmconfig = Set-AzureRmVMOSDisk -VM $vmconfig -Name $vmname"_osdisk1.vhd" -CreateOption FromImage -Windows -StorageAccountType $vmdisktype 
}else{
    $vmconfig = Set-AzureRmVMOSDisk -VM $vmconfig -Name $vmname"_osdisk1.vhd" -CreateOption FromImage -Linux -StorageAccountType $vmdisktype
}



if($enableVMBootLog -eq "Y"){
    $vmconfig = Set-AzureRmVMBootDiagnostics -VM $vmconfig -Enable -StorageAccountName $stgAccount -ResourceGroupName $stgAccountRG
}
if($enableVMBootLog -eq "N"){
    $vmconfig = Set-AzureRmVMBootDiagnostics -VM $vmconfig -Disable -ResourceGroupName $stgAccountRG
}

####################################################################################################################################
# Section1.1:  Attach data disks to VMs
####################################################################################################################################

if ($datadiskpresent -eq "y"){
    if(!$datadiskcsvpath){
        Write-Error "The script was ran without the -datadiskcsvpath parameter. Please run the script again passing the CSV path." -ErrorAction Stop
    }else{
        $lun = 0
        foreach($disk in $datadisklist){
            if ($disk.vmname -eq $vmname){
                $diskname = "$vmname-DataDisk-$lun"
                $datadisk = Get-AzureRmDisk -ResourceGroupName $resourceGroupName -DiskName $diskname
                if(!$datadisk){            
                    $diskConfig = New-AzureRmDiskConfig -AccountType $disk.accounttype -Location $location -CreateOption Empty -DiskSizeGB $disk.size
                    $datadisk = New-AzureRmDisk -Disk $diskConfig -ResourceGroupName $resourceGroupName -DiskName $diskname
                }
                $vmconfig = Add-AzureRmVMDataDisk -CreateOption Attach -Lun $lun -VM $vmconfig -ManagedDiskId $datadisk.Id
                $lun = $lun + 1
            }
        }
    }
}


####################################################################################################################################
# Section1.2:  Assign tags to VMs
####################################################################################################################################


if($vm.tagrequired -eq "y"){
    if(!$tagscsvpath){
        Write-Error "The script was ran without the -tagscsvpath parameter. Please run the script again passing the CSV path." -ErrorAction Stop
    }else{
        $alltags = @{}
        foreach($tag in $taglist){
            if($tag.vmname -eq $vmName){
                $alltags.Add($tag.tagname,$tag.tagvalue)
            }
        }
    }
}



####################################################################################################################################
# Section1.3:  Submit VM creation
####################################################################################################################################

try {
    #Check if there's any tag for that VM
    if($alltags){
        New-AzureRmVM -ResourceGroupName $resourceGroupName -Location $location -VM $vmconfig -Tag $alltags -AsJob -ErrorAction Stop
    }else{
        New-AzureRmVM -ResourceGroupName $resourceGroupName -Location $location -VM $vmconfig -AsJob -ErrorAction Stop
    }
}catch {
    Write-Output "Ran into an issue: $PSItem"
}}else{
    Write-Host "VM $vmName already exists. Skipping creation." -ForegroundColor Green
}

} #Closes the main foreach

while(Get-Job){
    Write-Host "--------------------------------------------------------------------------" -ForegroundColor Green
    write-host "Current active VM creation jobs. This will refresh each 15 seconds and will proceed to encrypting them when done." -ForegroundColor Green
    Write-Host "--------------------------------------------------------------------------" -ForegroundColor Green
    Get-Job
    Start-Sleep -Seconds 15
    Get-Job -State Completed | Remove-Job
    If(!(Get-Job -State Completed ) -and (!(Get-Job -State Running))){
        Write-Error "Verify failed jobs, fix and run the script again." -ErrorAction Stop
    }

}

 ####################################################################################################################################
# Section 2:  Assign tags to VMs after successfull creation
####################################################################################################################################
if(!$tagscsvpath){
    Write-Error "The script was ran without the -tagscsvpath parameter. Please run the script again passing the CSV path." -ErrorAction Stop
}else{
    $taglist = Import-Csv -Path $tagscsvpath

    foreach ($vm in $vmlist){ 
        if($vm.tagrequired -eq "y"){
            $alltags = $null
            foreach($tag in $taglist){
                $alltags += "$($tag.tagname) = '$($tag.tagvalue)'; "
            }
            Write-Host "Set-AzureRmResource -Tag @{$alltags} -ResourceName BLA -ResourceType BLA -ResourceGroupName BLA -Force "
        }
    }
} 

####################################################################################################################################
# Section 3:  Create AAD app if encryption is enabled using AAD. Fill in $aadClientSecret variable if AAD app was already created.
####################################################################################################################################
Clear-Host
Write-Host "Starting encryption of all VMs" -ForegroundColor Green
Write-Host "Checking if AAD application already exists and if not create one." -ForegroundColor Yellow
$azureResourcesModule = Get-Module 'AzureRM.Resources';
if($aadAppName)
{
    # Check if AAD app with $aadAppName was already created
    $SvcPrincipals = (Get-AzureRmADServicePrincipal -SearchString $aadAppName);
    if(-not $SvcPrincipals)
    {
        # Create a new AD application if not created before
        $identifierUri = [string]::Format("http://localhost:8080/{0}",[Guid]::NewGuid().ToString("N"));
        $defaultHomePage = 'http://version1.com';
        $now = [System.DateTime]::Now;
        $oneYearFromNow = $now.AddYears(1);
        $aadClientSecret = [Guid]::NewGuid().ToString();
        Write-Host "AAD application not found. Creating new AAD application ($aadAppName)" -ForegroundColor Green;

        if($azureResourcesModule.Version.Major -ge 5)
        {
            $secureAadClientSecret = ConvertTo-SecureString -String $aadClientSecret -AsPlainText -Force;
            $ADApp = New-AzureRmADApplication -DisplayName $aadAppName -HomePage $defaultHomePage -IdentifierUris $identifierUri  -StartDate $now -EndDate $oneYearFromNow -Password $secureAadClientSecret;
        }
        else
        {
            $ADApp = New-AzureRmADApplication -DisplayName $aadAppName -HomePage $defaultHomePage -IdentifierUris $identifierUri  -StartDate $now -EndDate $oneYearFromNow -Password $aadClientSecret;
        }

        $servicePrincipal = New-AzureRmADServicePrincipal -ApplicationId $ADApp.ApplicationId;
        $SvcPrincipals = (Get-AzureRmADServicePrincipal -SearchString $aadAppName);
        if(-not $SvcPrincipals)
        {
            # AAD app wasn't created 
            Write-Error "Failed to create AAD app $aadAppName. Please log in to Azure using Connect-AzureRmAccount and try again";
            return;
        }
        $aadClientID = $servicePrincipal.ApplicationId;
        Write-Host "Created a new AAD Application ($aadAppName) with ID: $aadClientID " -ForegroundColor Gray;
    }
    else
    {
        if(-not $aadClientSecret){
            $aadClientSecret = Read-Host -Prompt "Aad application ($aadAppName) was already created, input corresponding aadClientSecret and hit ENTER. It can be retrieved from https://portal.azure.com portal" ;
        }
        if(-not $aadClientSecret){
            Write-Error "Aad application ($aadAppName) was already created. Re-run the script by supplying aadClientSecret parameter with corresponding secret from https://portal.azure.com portal";
            return;
        }
        
        $aadClientID = $SvcPrincipals[0].ApplicationId;
        
    }
}

Try
{
    $keyVault = Get-AzureRmKeyVault -VaultName $keyVaultName -ErrorAction Stop;
}
Catch [System.ArgumentException]
{
    Write-Host "Couldn't find Key Vault: $keyVaultName";
    $keyVault = $null;
}
    

if($aadAppName)
{
    # Specify privileges to the vault for the AAD application - https://msdn.microsoft.com/en-us/library/mt603625.aspx
    Set-AzureRmKeyVaultAccessPolicy -VaultName $keyVaultName -ServicePrincipalName $aadClientID -PermissionsToKeys wrapKey -PermissionsToSecrets set;
}

Set-AzureRmKeyVaultAccessPolicy -VaultName $keyVaultName -EnabledForDiskEncryption;

# Enable soft delete on KeyVault to not lose encryption secrets
$resource = Get-AzureRmResource -ResourceId $keyVault.ResourceId;
if($resource.Properties.enableSoftDelete -ne $true){
    Write-Host "Enabling Soft Delete on KeyVault $keyVaultName" -ForegroundColor Green;
    $resource.Properties | Add-Member -MemberType "NoteProperty" -Name "enableSoftDelete" -Value "true" -Force;
    Set-AzureRmResource -resourceid $resource.ResourceId -Properties $resource.Properties -Force;
}


# Enable ARM resource lock on KeyVault to prevent accidental key vault deletion
if(!(Get-AzureRmResourceLock | ?{$_.name -match "LockKeyVault"})){
    Write-Host "Adding resource lock on  KeyVault $keyVaultName" -ForegroundColor Green;
    $lockNotes = "KeyVault may contain AzureDiskEncryption secrets required to boot encrypted VMs";
    New-AzureRmResourceLock -LockLevel CanNotDelete -LockName "LockKeyVault" -ResourceName $resource.Name -ResourceType $resource.ResourceType -ResourceGroupName $resource.ResourceGroupName -LockNotes $lockNotes -Force; 
}



########################################################################################################################
# Section3: Loop through the selected list of VMs and enable encryption
########################################################################################################################

$diskEncryptionKeyVaultUrl = $keyVault.VaultUri;
$keyVaultResourceId = $keyVault.ResourceId;
$allVMs = foreach($csvvm in $vmlist){
    Get-AzureRmVM -Name $csvvm.VMName -ResourceGroupName $csvvm.ResourceGroupName
}

foreach($vm in $allVMs)
{
    if($vm.Location.replace(' ','').ToLower() -ne $keyVault.Location.replace(' ','').ToLower())
    {
        Write-Error "To enable AzureDiskEncryption, VM and KeyVault must belong to same subscription and same region. vm Location:  $($vm.Location.ToLower()) , keyVault Location: $($keyVault.Location.ToLower())";
        return;
    }

    Write-Host "Encrypting VM: $($vm.Name) in ResourceGroup: $($vm.ResourceGroupName) " -foregroundcolor Green;
    if($aadAppName)
    {
        Start-Job -ScriptBlock {param($context,$rg,$vmn,$AADID,$AADpwd,$diskurl,$kvid) Set-AzureRmVMDiskEncryptionExtension -ResourceGroupName $rg -VMName $vmn -AadClientID $AADID -AadClientSecret $AADpwd -DiskEncryptionKeyVaultUrl $diskurl -DiskEncryptionKeyVaultId $kvid -VolumeType 'All' -SkipVmBackup -Confirm:$false -Force -ErrorAction Continue} -ArgumentList ((Get-AzureRmContext),$vm.ResourceGroupName,$vm.Name,$aadClientID,$aadClientSecret,$diskEncryptionKeyVaultUrl,$keyVaultResourceId)
    }
    else
    {
        Write-Error "Could not find AAD application. Please make sure it is created and rerun the script."
    }
}
while(Get-Job){
    
    write-host "Current active VM creation jobs. This will refresh each 15 seconds and will proceed to encrypting them when done." -ForegroundColor Green
    Write-Host "--------------------------------------------------------------------------"
    Get-Job
    Start-Sleep -Seconds 15
    Get-Job -State Completed | Remove-Job
    }
Stop-Transcript
Write-Host "Script Finished"