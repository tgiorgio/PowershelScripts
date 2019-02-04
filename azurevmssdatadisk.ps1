$disks = Get-Disk | Where partitionstyle -eq 'raw' | Sort-Object number

$letters = 70..89 | ForEach-Object { [char]$_ }
$count = 0
$label = "datadisk"

foreach ($disk in $disks) {
    $driveLetter = $letters[$count].ToString()
    $disk | 
    Initialize-Disk -PartitionStyle MBR -PassThru |
    New-Partition -UseMaximumSize -DriveLetter $driveLetter |
    Format-Volume -FileSystem NTFS -NewFileSystemLabel $label.$count -Confirm:$false -Force
$count++
}