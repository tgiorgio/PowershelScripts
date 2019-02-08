$logpath = "C:\ScriptOutput"

if(!(Test-Path $logpath)){
    New-Item -Path $logpath -ItemType Directory -Force
}

Get-NetAdapter | Out-File $logpath\NetworkAdapater.txt