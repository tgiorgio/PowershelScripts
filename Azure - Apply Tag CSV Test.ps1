$taglist = Import-Csv -Path "C:\Users\digiorgiot\OneDrive - Version 1\Customers\SIA\ScriptFinal\vmtags.csv"
$vmlist = Import-Csv -Path "C:\Users\digiorgiot\OneDrive - Version 1\Customers\SIA\ScriptFinal\vmtocreatetest.csv"

foreach ($vm in $vmlist){ 
    if($vm.tagrequired -eq "y"){
        $alltags = @{}
        foreach($tag in $taglist){
            $alltags.Add($tag.tagname,$tag.tagvalue)
        }
        Write-Host "Set-AzureRmResource -Tag @{$alltags} -ResourceName BLA -ResourceType BLA -ResourceGroupName BLA -Force "
    }
}