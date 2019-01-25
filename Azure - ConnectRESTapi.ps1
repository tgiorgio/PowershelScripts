# Variables
$TenantId = "5a24b4ad-b6ca-41cc-bf67-c6956b6c0535"
$ApplicationID = "ad704843-5806-42de-a4e3-7cdbbe77ca3a"
$ApplicationKey = "N28U2WRFsmN1suhu11rkpC8FKVmYEAZNF8tCwr5xVo4="
$ARMResource = "https://management.core.windows.net/"
$TokenEndpoint = "https://login.microsoftonline.com/$TenantId/oauth2/token"
$SubscriptionId = "3295821e-755e-44ed-acd8-ababa891ee7a"
$SubscriptionIdNew = "ae2a2f30-8637-42e7-b861-96dbe0240263"

$Body = @{
    'resource' = $ARMResource
    'client_id' = $ApplicationID
    'grant_type' = 'Client_credentials'
    'client_secret' = $ApplicationKey
}

$params = @{
    ContentType = 'application/x-www-form-urlencoded'
    Headers = @{'accept'='application/json'}
    Body = $Body
    Method = 'Post'
    URI = $TokenEndpoint
}

$token = Invoke-RestMethod @params

$uri = "https://management.azure.com/subscriptions/$SubscriptionId/providers/Microsoft.ClassicCompute/validateSubscriptionMoveAvailability?api-version=2016-04-01"


$bodyparameters = @{
    role = "source"
}
$params2 = @{
    ContentType = 'application/json'
    Headers = @{
            'authorization' = "Bearer $($token.access_token)"
        }
    Body = (ConvertTo-Json $bodyparameters)
    Method = 'Post'
    URI = $uri
}
$response = Invoke-RestMethod @params2


$urinew = "https://management.azure.com/subscriptions/$SubscriptionIdNew/providers/Microsoft.ClassicCompute/validateSubscriptionMoveAvailability?api-version=2016-04-01"
$bodyparametersnew = @{
    role = "target"
}
$paramsnew = @{
    ContentType = 'application/json'
    Headers = @{
            'authorization' = "Bearer $($token.access_token)"
        }
    Body = (ConvertTo-Json $bodyparametersnew)
    Method = 'Post'
    URI = $urinew
}
$responsenew = Invoke-RestMethod @paramsnew