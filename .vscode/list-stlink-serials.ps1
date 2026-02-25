# Lists STMicroelectronics devices and prints each unique serial once as:
# "project.stLinkSerial": "<serial>"

try {
    $serials = [System.Collections.Generic.HashSet[string]]::new()

    if (Get-Command Get-PnpDevice -ErrorAction SilentlyContinue) {
        $devices = Get-PnpDevice -PresentOnly | Where-Object { $_.Manufacturer -like 'STMicroelectronics*' }
        if ($devices) {
            foreach ($d in $devices) {
                $id = $d.InstanceId
                $parentProp = Get-PnpDeviceProperty -InstanceId $id -KeyName 'DEVPKEY_Device_Parent' -ErrorAction SilentlyContinue
                if ($parentProp -and $parentProp.Data) {
                    $parent = $parentProp.Data
                    if ($parent -match '\\([^\\]+)$') { $lastToken = $matches[1] } else { $lastToken = $parent }
                    if ($lastToken -match '([0-9A-Fa-f]{8,})') { $serial = $matches[1] } elseif ($parent -match '([0-9A-Fa-f]{8,})') { $serial = $matches[1] } else { $serial = $lastToken }
                    $null = $serials.Add($serial)
                } else {
                    $last = ($id -split '\\')[-1]
                    if ($last -match '([0-9A-Fa-f]{8,})') { $serial = $matches[1] } else { $serial = $last }
                    $null = $serials.Add($serial)
                }
            }
        }
    } else {
        # Fallback to WMI query if Get-PnpDevice is not available
        $devices = Get-WmiObject Win32_PnPEntity -Filter "Manufacturer LIKE 'STMicroelectronics%'"
        if ($devices) {
            foreach ($d in $devices) {
                $pn = $d.PNPDeviceID
                $last = ($pn -split '\\')[-1]
                if ($last -match '([0-9A-Fa-f]{8,})') { $serial = $matches[1] } elseif ($pn -match '([0-9A-Fa-f]{8,})') { $serial = $matches[1] } else { $serial = $last }
                $null = $serials.Add($serial)
            }
        }
    }

    # Print unique serials one-per-line (no saving, no interactive menu)
    $arr = @($serials | Sort-Object | ForEach-Object { [string]$_ })
    foreach ($s in $arr) { Write-Output $s }

} catch {
    Write-Error "Error enumerating devices: $_"
}
