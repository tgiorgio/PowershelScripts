$resourcegroups = Get-Content "C:\Users\digiorgiot\OneDrive - Version 1\Customers\SIA\PREPROD_RG.txt"

foreach($rg in $resourcegroups){
    New-AzResourceGroup -Name $rg -Location uksouth
}