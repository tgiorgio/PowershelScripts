param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$trustedHosts
)

msiexec.exe /qn /l* log.txt /i Opsview_Windows_Agent_x64_24-09-18-1500.msi ALLOWED_HOSTS=$trustedHosts
Start-Service OpsviewAgent