<#
1. Availability set on the same RG as VM
2. Existent disk must be on same RG as the VM
3. Existent vNIC must be on same RG as the VM
4. Existent DATA DISK must be on same RG as the VM
#>

$resourceGroupName = ""
$location = ""
$vmName = ""
$vmsize = "Standard_A2_V2"
$availSetName = ""
$zones = ""
$osType = "Windows" #Windows or Linux
#Fill this to use existent nic
$nicname = ""
#Fill these to create a new nic
$vnetname = "V1-POC-VNET1"
$vnetRG = "V1-POC-Network"
$subnetname = "Production"

#Fill this to use existent OS disk
$diskname = ""
#Fill this to create a new OS disk
$publisher = "MicrosoftWindowsServer"
$offer = "WindowsServer"
$sku = "2016-DATACENTER"
$vmdisktype = "StandardSSD_LRS"

#Fill this to attach existent data disk
$dataDiskName = ""


#Fill these to enable boot diagnostics 
$enableVMBootLog = "" # Y or N
$stgAccount = ""
$stgAccountRG = ""


############ 1. Create VNIC ###########################################

if(!$nicname){
    $nicname = "$vmName-NIC"
}
$nic = Get-AzureRmNetworkInterface -Name $nicname -ResourceGroupName $resourceGroupName -ErrorAction SilentlyContinue

if(!$nic){
    $vnet = Get-AzureRmVirtualNetwork -Name $vnetname -ResourceGroupName $vnetRG
    $subnet = $vnet.Subnets | ?{$_.Name -eq $subnetname }

    try {
        $nic = New-AzureRmNetworkInterface -Name $nicname -ResourceGroupName $resourceGroupName -Location $location -SubnetId $subnet.id -IpConfigurationName "$vmname-IP" -ErrorAction Stop
    }
    catch {
        Write-Host "Error creating VNIC" -ForegroundColor Red
    }
}
#######################################################################


############ 2. Create VM Config ###########################################
if($osType -match "Windows"){
    if(!$diskname){
        $cred = Get-Credential
        if($availSetName){
            $availSet = Get-AzureRmAvailabilitySet -ResourceGroupName $resourceGroupName -Name $availSetName
            
            if($offer -match "Windows"){
                $vmconfig = New-AzureRmVMConfig -VMName $vmName -VMSize $vmsize -AvailabilitySetId $availSet.id| Set-AzureRmVMOperatingSystem -Windows -ComputerName $vmName -Credential $cred | Set-AzureRmVMSourceImage -PublisherName $publisher -Offer $Offer -Skus $sku -Version Latest | Add-AzureRmVMNetworkInterface -Id $nic.Id
            }else{
                $vmconfig = New-AzureRmVMConfig -VMName $vmName -VMSize $vmsize -AvailabilitySetId $availSet.id | Set-AzureRmVMOperatingSystem -Linux -ComputerName $vmName -Credential $cred | Set-AzureRmVMSourceImage -PublisherName $publisher -Offer $offer -Skus $sku -Version Latest | Add-AzureRmVMNetworkInterface -Id $nic.Id
            }
        }else{
            if($offer -match "Windows"){
                $vmconfig = New-AzureRmVMConfig -VMName $vmName -VMSize $vmsize -Zone 2 | Set-AzureRmVMOperatingSystem -Windows -ComputerName $vmName -Credential $cred | Set-AzureRmVMSourceImage -PublisherName $publisher -Offer $Offer -Skus $sku -Version Latest | Add-AzureRmVMNetworkInterface -Id $nic.Id
            }else{
                $vmconfig = New-AzureRmVMConfig -VMName $vmName -VMSize $vmsize -Zone 2| Set-AzureRmVMOperatingSystem -Linux -ComputerName $vmName -Credential $cred | Set-AzureRmVMSourceImage -PublisherName $publisher -Offer $offer -Skus $sku -Version Latest | Add-AzureRmVMNetworkInterface -Id $nic.Id
            }
        }

        if($offer -match "Windows"){
            $vmconfig = Set-AzureRmVMOSDisk -VM $vmconfig -Name $vmname"_osdisk1.vhd" -CreateOption FromImage -Windows -StorageAccountType $vmdisktype 
        }else{
            $vmconfig = Set-AzureRmVMOSDisk -VM $vmconfig -Name $vmname"_osdisk1.vhd" -CreateOption FromImage -Linux -StorageAccountType $vmdisktype
        }

    }else{
        $osdisk = Get-AzureRmDisk -DiskName $diskname -ResourceGroupName $resourceGroupName

        if($availSetName){
            $availSet = Get-AzureRmAvailabilitySet -ResourceGroupName $resourceGroupName -Name $availSetName
            $vmconfig = New-AzureRmVMConfig -VMName $vmName -VMSize $vmsize -AvailabilitySetId $availSet.id| Add-AzureRmVMNetworkInterface -Id $nic.Id
            
        }else{
            $vmconfig = New-AzureRmVMConfig -VMName $vmName -VMSize $vmsize |  Add-AzureRmVMNetworkInterface -Id $nic.Id
        }
        $vmconfig = Set-AzureRmVMOSDisk -VM $vmconfig -ManagedDiskId $osdisk.Id -StorageAccountType $osdisk.sku.name -DiskSizeInGB $osdisk.DiskSizeGB -CreateOption Attach -Windows
    }
}else{
    if(!$diskname){
        $cred = Get-Credential
        if($availSetName){
            $availSet = Get-AzureRmAvailabilitySet -ResourceGroupName $resourceGroupName -Name $availSetName
            
            if($offer -match "Windows"){
                $vmconfig = New-AzureRmVMConfig -VMName $vmName -VMSize $vmsize -AvailabilitySetId $availSet.id| Set-AzureRmVMOperatingSystem -Windows -ComputerName $vmName -Credential $cred | Set-AzureRmVMSourceImage -PublisherName $publisher -Offer $Offer -Skus $sku -Version Latest | Add-AzureRmVMNetworkInterface -Id $nic.Id
            }else{
                $vmconfig = New-AzureRmVMConfig -VMName $vmName -VMSize $vmsize -AvailabilitySetId $availSet.id | Set-AzureRmVMOperatingSystem -Linux -ComputerName $vmName -Credential $cred | Set-AzureRmVMSourceImage -PublisherName $publisher -Offer $offer -Skus $sku -Version Latest | Add-AzureRmVMNetworkInterface -Id $nic.Id
            }
        }else{
            if($offer -match "Windows"){
                $vmconfig = New-AzureRmVMConfig -VMName $vmName -VMSize $vmsize | Set-AzureRmVMOperatingSystem -Windows -ComputerName $vmName -Credential $cred | Set-AzureRmVMSourceImage -PublisherName $publisher -Offer $Offer -Skus $sku -Version Latest | Add-AzureRmVMNetworkInterface -Id $nic.Id
            }else{
                $vmconfig = New-AzureRmVMConfig -VMName $vmName -VMSize $vmsize | Set-AzureRmVMOperatingSystem -Linux -ComputerName $vmName -Credential $cred | Set-AzureRmVMSourceImage -PublisherName $publisher -Offer $offer -Skus $sku -Version Latest | Add-AzureRmVMNetworkInterface -Id $nic.Id
            }
        }

        if($offer -match "Windows"){
            $vmconfig = Set-AzureRmVMOSDisk -VM $vmconfig -Name $vmname"_osdisk1.vhd" -CreateOption FromImage -Windows -StorageAccountType $vmdisktype 
        }else{
            $vmconfig = Set-AzureRmVMOSDisk -VM $vmconfig -Name $vmname"_osdisk1.vhd" -CreateOption FromImage -Linux -StorageAccountType $vmdisktype
        }

    }else{
        $osdisk = Get-AzureRmDisk -DiskName $diskname -ResourceGroupName $resourceGroupName

        if($availSetName){
            $availSet = Get-AzureRmAvailabilitySet -ResourceGroupName $resourceGroupName -Name $availSetName
            $vmconfig = New-AzureRmVMConfig -VMName $vmName -VMSize $vmsize -AvailabilitySetId $availSet.id| Add-AzureRmVMNetworkInterface -Id $nic.Id
            
        }else{
            $vmconfig = New-AzureRmVMConfig -VMName $vmName -VMSize $vmsize |  Add-AzureRmVMNetworkInterface -Id $nic.Id
        }
        $vmconfig = Set-AzureRmVMOSDisk -VM $vmconfig -ManagedDiskId $osdisk.Id -StorageAccountType $osdisk.sku.name -DiskSizeInGB $osdisk.DiskSizeGB -CreateOption Attach -Linux
    }
}

if($enableVMBootLog -eq "Y"){
    $vmconfig = Set-AzureRmVMBootDiagnostics -VM $vmconfig -Enable -StorageAccountName $stgAccount -ResourceGroupName $stgAccountRG
}else{
    $vmconfig = Set-AzureRmVMBootDiagnostics -VM $vmconfig -Disable
}

if($dataDiskName){
    $datadisk = Get-AzureRmDisk -ResourceGroupName $rgName -DiskName $dataDiskName 
    $vmconfig = Add-AzureRmVMDataDisk -CreateOption Attach -Lun 0 -VM $vmconfig -ManagedDiskId $datadisk.Id
}
#######################################################################

############ 1. Create Virtual Machine ###########################################
try {
    New-AzureRmVM -ResourceGroupName $resourceGroupName -Location $location -VM $vmconfig -ErrorAction Stop
}
catch {
    Write-Output "Ran into an issue: $PSItem"
}

