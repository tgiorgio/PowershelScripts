$features = "Web-Server,Web-WebServer,Web-Common-Http,Web-Static-Content,Web-Default-Doc,Web-Dir-Browsing,Web-Http-Errors,Web-Health,Web-Http-Logging,Web-Performance,Web-Stat-Compression,Web-Security,Web-Filtering"

$winversionmajor = [System.Environment]::OSVersion.Version.Major
$winversionminor = [System.Environment]::OSVersion.Version.Minor

If(($winversionmajor -eq 6) -and ($winversionminor -eq 1)){
Add-WindowsFeature -Name "$features,Web-Mgmt-Tools,Web-Mgmt-Console"
}else{
    Add-WindowsFeature -Name $features -IncludeManagementTools
}