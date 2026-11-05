@echo off
chcp 65001 >nul
title Uhrwerk-Insel aktualisieren
cd /d "%~dp0"
echo ============================================
echo   Uhrwerk-Insel: neueste Version holen
echo ============================================
where git >nul 2>nul
if errorlevel 1 (
  echo Git ist nicht installiert: https://git-scm.com/downloads/win
  pause
  exit /b 1
)
if not exist ".git" (
  echo Dieser Ordner ist noch nicht mit GitHub verbunden.
  echo Bitte einmal einrichten - siehe README.md, Abschnitt "Updates holen".
  pause
  exit /b 1
)
git pull origin master
if errorlevel 1 (
  echo.
  echo Konnte nicht aktualisieren - vermutlich gibt es eigene Aenderungen in den Dateien.
  echo Frag Claude im Terminal: "Hol die neueste Version von GitHub und behalte meine Aenderungen."
  pause
  exit /b 1
)
echo.
echo Fertig! Jetzt startet Rojo. In Roblox Studio: Plugins - Rojo - Connect.
echo Falls Zonen/Strecken/Deko neu sind: Welt neu bauen (siehe README).
echo Dieses Fenster offen lassen, solange du in Studio arbeitest.
echo.
where rojo >nul 2>nul
if errorlevel 1 (
  if exist "rojo.exe" (
    rojo.exe serve
  ) else (
    echo rojo wurde nicht gefunden. Lege rojo.exe in diesen Ordner.
    pause
  )
) else (
  rojo serve
)
