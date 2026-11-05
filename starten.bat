@echo off
chcp 65001 >nul
title Uhrwerk-Insel starten
cd /d "%~dp0"

rem ============================================================
rem  Startet alles mit einem Klick:
rem   1. Rojo  (überträgt den Code live nach Roblox Studio)
rem   2. Roblox Studio mit dem Spiel "Uhrwerk-Insel"
rem   3. Claude Code
rem ============================================================

rem --- 1. Rojo ---
if exist "rojo.exe" (
  start "Rojo - Uhrwerk-Insel" powershell -NoExit -Command "$Host.UI.RawUI.WindowTitle = 'Rojo - Uhrwerk-Insel'; Write-Host 'Rojo laeuft. In Roblox Studio: Plugins - Rojo - Connect. Dieses Fenster offen lassen.' -ForegroundColor Green; .\rojo.exe serve"
) else (
  start "Rojo - Uhrwerk-Insel" powershell -NoExit -Command "Write-Host 'rojo.exe fehlt in diesem Ordner.' -ForegroundColor Red; rojo serve"
)

rem --- 2. Roblox Studio direkt mit dem Spiel öffnen ---
rem (Place-ID und Universe-ID stehen im Creator Dashboard; der Link funktioniert auch nach Roblox-Updates)
start "" "roblox-studio:1+launchmode:edit+task:EditPlace+placeId:136253220476760+universeId:10774788340"

rem --- 3. Claude Code ---
start "Claude - Uhrwerk-Insel" powershell -NoExit -Command "$Host.UI.RawUI.WindowTitle = 'Claude - Uhrwerk-Insel'; claude"

exit /b 0
