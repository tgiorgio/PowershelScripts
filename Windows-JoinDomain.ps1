Param(
  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]$domainname,

  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]$username,

  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [String]$userpassword

)

$securepassword = ConvertTo-SecureString $userpassword -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ($username,$securepassword)

Add-Computer -DomainName $domainname -Credential $cred -restart –force