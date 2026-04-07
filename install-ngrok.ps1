# Script PowerShell pour installer et lancer ngrok
# Lance ce script dans PowerShell

# Télécharger ngrok
Write-Host "Téléchargement de ngrok..." -ForegroundColor Cyan
Invoke-WebRequest -Uri "https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-windows-amd64.zip" -OutFile "$env:TEMP\ngrok.zip"

# Décompresser
Write-Host "Installation..." -ForegroundColor Cyan
Expand-Archive -Path "$env:TEMP\ngrok.zip" -DestinationPath "C:\ngrok" -Force

# Ajouter au PATH
$env:PATH += ";C:\ngrok"

Write-Host "ngrok installé ! Lance maintenant : ngrok http 3000" -ForegroundColor Green
