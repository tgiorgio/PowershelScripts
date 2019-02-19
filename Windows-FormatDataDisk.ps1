$disks = Get-Disk | Where-Object partitionstyle -eq 'raw' | Sort-Object number

$count = 0
$label = "datadisk"

foreach ($disk in $disks) {
Write-Host "Starting disk $disk"
    $partitions = Get-Partition
    $array =@()
    foreach ($lt in $partitions){
        $array += [int][char]$lt.driveletter
    }
    $newletter = [char][int](($array| Measure-Object -Maximum).maximum + 1)
    $disk | Initialize-Disk -PartitionStyle MBR -PassThru
    New-Partition -UseMaximumSize -DriveLetter $newletter -DiskId $disk.UniqueId
    Format-Volume -DriveLetter $newletter -FileSystem NTFS -NewFileSystemLabel "$label$count" -Confirm:$false -Force
$count++
}