@echo off
chcp 65001 >nul
title Uhrwerk-Insel starten
cd /d "%~dp0"

rem Fenster 1: Rojo (überträgt den Code live nach Roblox Studio)
if exist "rojo.exe" (
  start "Rojo - Uhrwerk-Insel" powershell -NoExit -Command "$Host.UI.RawUI.WindowTitle = 'Rojo - Uhrwerk-Insel'; Write-Host 'Rojo laeuft. In Roblox Studio: Plugins - Rojo - Connect. Dieses Fenster offen lassen.' -ForegroundColor Green; .\rojo.exe serve"
) else (
  start "Rojo - Uhrwerk-Insel" powershell -NoExit -Command "Write-Host 'rojo.exe fehlt in diesem Ordner.' -ForegroundColor Red; rojo serve"
)

rem Fenster 2: Claude Code
start "Claude - Uhrwerk-Insel" powershell -NoExit -Command "$Host.UI.RawUI.WindowTitle = 'Claude - Uhrwerk-Insel'; claude"

exit /b 0
