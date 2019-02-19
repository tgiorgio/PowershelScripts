$resourcegroups = Get-Content C:\temp\rgs.txt

foreach($rg in $resourcegroups){
    New-AzResourceGroup -Name $rg -Location uksouth
}