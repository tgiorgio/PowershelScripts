$users = Import-Csv -Path C:\temp\users.csv

foreach($user in $users){

$securepassword = ConvertTo-SecureString $user.password -AsPlainText -Force

New-ADUser -Name $user.fullname -GivenName $user.firstname -Surname $user.lastname -SamAccountName $user.accountname -UserPrincipalName $user.upn -Path "OU=V1_accounts,DC=siadevinternal,DC=net" -AccountPassword $securepassword -Enabled $true

}