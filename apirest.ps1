# Get root path of this script.
#$CurrentDirPath = Split-Path $MyInvocation.MyCommand.Path

# Import Utility Module
#Import-Module -Name "$CurrentDirPath\Module\Utility" -Verbose -DisableNameChecking

# Variables
$TenantId = "5a24b4ad-b6ca-41cc-bf67-c6956b6c0535"
$ClientId = "ad704843-5806-42de-a4e3-7cdbbe77ca3a"
$ClientSecret = "N28U2WRFsmN1suhu11rkpC8FKVmYEAZNF8tCwr5xVo4="
$Resource = "https://management.core.windows.net/"
$ApiUri = "https://login.microsoftonline.com/$TenantId/oauth2/token"
$SubscriptionId = "3295821e-755e-44ed-acd8-ababa891ee7a"

# Functions
Function New-AccessToken
{
    $Response = Get-AccessToken -GrantType client_credentials -ClientId $ClientId -ClientSecret $ClientSecret -Resource $Resource -ApiUri $ApiUri
    $Token | ConvertTo-Json | Out-File "token.json" -Force
    Write-Output "New token generated."
    return $Response
}

$Token = New-AccessToken

<# # Get Access Token
if (!(Test-Path -Path "$CurrentDirPath\token.json"))
{
    Write-Output "Getting new token."
    $Token = New-AccessToken
}
else 
{
    $Token = Get-Content -Raw -Path "$CurrentDirPath\token.json" | ConvertFrom-Json
    # Check if token is expired.
    $epoch = [datetime]"1/1/1970"
    $ExpiresOn = $epoch.AddSeconds($Token.expires_on)
    if ($ExpiresOn -lt [datetime]::Now)
    {
        Write-Output "Token has expired and will be reviewed."
        $Token = New-AccessToken
    }
    else
    {
        Write-Output "Token is valid and ready to be used."
    }
} #>
# Get Azure Resource Groups
$uri = "https://management.azure.com/subscriptions/f9060c6d-5198-4e2b-8e91-9f3b34c74305/providers/Microsoft.ClassicCompute/validateSubscriptionMoveAvailability?api-version=2016-04-01"

$Headers = @{}
$bodyparameters = @{
    role = "source"
}
$body = (ConvertTo-Json $bodyparameters)

$Headers.Add("Authorization","$($Token.token_type) "+ " " + "$($Token.access_token)")

Invoke-RestMethod -Method Post -Uri $uri -Headers $Headers -Body $body

#Write-Output $ResourceGroups