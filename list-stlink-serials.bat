
@echo off
rem Standalone wrapper: embed PowerShell script into a temp .ps1, run it, keep window open, then cleanup
setlocal

set "PS1_FILE=%TEMP%\list-stlink-serials-%RANDOM%.ps1"

rem Create the temporary PowerShell script
echo( # Lists STMicroelectronics devices and prints each unique serial once as: > "%PS1_FILE%"
echo( # "project.stLinkSerial": "<serial>" >> "%PS1_FILE%"
echo( >> "%PS1_FILE%"
echo( try { >> "%PS1_FILE%"
echo(     $serials = [System.Collections.Generic.HashSet[string]]::new() >> "%PS1_FILE%"
echo( >> "%PS1_FILE%"
echo(     if (Get-Command Get-PnpDevice -ErrorAction SilentlyContinue) { >> "%PS1_FILE%"
echo(         $devices = Get-PnpDevice -PresentOnly ^| Where-Object { $_.Manufacturer -like 'STMicroelectronics*' } >> "%PS1_FILE%"
echo(         if ($devices) { >> "%PS1_FILE%"
echo(             foreach ($d in $devices) { >> "%PS1_FILE%"
echo(                 $id = $d.InstanceId >> "%PS1_FILE%"
echo(                 $parentProp = Get-PnpDeviceProperty -InstanceId $id -KeyName 'DEVPKEY_Device_Parent' -ErrorAction SilentlyContinue >> "%PS1_FILE%"
echo(                 if ($parentProp -and $parentProp.Data) { >> "%PS1_FILE%"
echo(                     $parent = $parentProp.Data >> "%PS1_FILE%"
echo(                     if ($parent -match '\\([^\\]+)$') { $lastToken = $matches[1] } else { $lastToken = $parent } >> "%PS1_FILE%"
echo(                     if ($lastToken -match '([0-9A-Fa-f]{8,})') { $serial = $matches[1] } elseif ($parent -match '([0-9A-Fa-f]{8,})') { $serial = $matches[1] } else { $serial = $lastToken } >> "%PS1_FILE%"
echo(                     $null = $serials.Add($serial) >> "%PS1_FILE%"
echo(                 } else { >> "%PS1_FILE%"
echo(                     $last = ($id -split '\\')[-1] >> "%PS1_FILE%"
echo(                     if ($last -match '([0-9A-Fa-f]{8,})') { $serial = $matches[1] } else { $serial = $last } >> "%PS1_FILE%"
echo(                     $null = $serials.Add($serial) >> "%PS1_FILE%"
echo(                 } >> "%PS1_FILE%"
echo(             } >> "%PS1_FILE%"
echo(         } >> "%PS1_FILE%"
echo(     } else { >> "%PS1_FILE%"
echo(         # Fallback to WMI query if Get-PnpDevice is not available >> "%PS1_FILE%"
echo(         $devices = Get-WmiObject Win32_PnPEntity -Filter "Manufacturer LIKE 'STMicroelectronics%'" >> "%PS1_FILE%"
echo(         if ($devices) { >> "%PS1_FILE%"
echo(             foreach ($d in $devices) { >> "%PS1_FILE%"
echo(                 $pn = $d.PNPDeviceID >> "%PS1_FILE%"
echo(                 $last = ($pn -split '\\')[-1] >> "%PS1_FILE%"
echo(                 if ($last -match '([0-9A-Fa-f]{8,})') { $serial = $matches[1] } elseif ($pn -match '([0-9A-Fa-f]{8,})') { $serial = $matches[1] } else { $serial = $last } >> "%PS1_FILE%"
echo(                 $null = $serials.Add($serial) >> "%PS1_FILE%"
echo(             } >> "%PS1_FILE%"
echo(         } >> "%PS1_FILE%"
echo(     } >> "%PS1_FILE%"
echo( >> "%PS1_FILE%"
echo(     # Print unique serials one-per-line (no saving, no interactive menu) >> "%PS1_FILE%"
echo(     $arr = @($serials ^| Sort-Object ^| ForEach-Object { [string]$_ }) >> "%PS1_FILE%"
echo(     foreach ($s in $arr) { Write-Output $s } >> "%PS1_FILE%"
echo( >> "%PS1_FILE%"
echo( } catch { >> "%PS1_FILE%"
echo(     Write-Error "Error enumerating devices: $_" >> "%PS1_FILE%"
echo( } >> "%PS1_FILE%"

rem Run the generated PowerShell script
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS1_FILE%"
set "RC=%ERRORLEVEL%"

rem Keep window open so user can read output
pause

rem Cleanup temporary script
del "%PS1_FILE%" >nul 2^>^&1

endlocal

exit /b %RC%
