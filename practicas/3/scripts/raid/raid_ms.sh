# Comandos útiles

### Averiguar si un disco puede ser usado para RAID
Get-PhysicalDisk | Where-Object DeviceId -ne 0 | Select-Object FriendlyName, CanPool, CannotPoolReason

### Inicialización
Get-Disk | Where-Object Number -ne 0 | Set-Disk -IsOffline $false
Get-Disk | Where-Object Number -ne 0 | Set-Disk -IsReadOnly $false
Get-Disk | Where-Object Number -ne 0 | Clear-Disk -RemoveData -RemoveOEM -Confirm:$false
Get-Disk | Where-Object Number -ne 0 | Initialize-Disk -PartitionStyle GPT

### Exportar eventos
Get-EventLog -LogName System -After (Get-Date).AddHours(-2) |
    Where-Object { $_.Source -match "Disk|VDS|Ntfs" -and ($_.EntryType -match "Error|Warning") } |
    Select-Object TimeGenerated, Source, Message |
    Export-Csv -Path "D:\SUPERMEMORIA\windows\raid\windows.csv" -NoTypeInformation -Encoding UTF8