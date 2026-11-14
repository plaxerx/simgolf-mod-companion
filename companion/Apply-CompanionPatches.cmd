@echo off
rem Double-click: patch the installed SimGolf Remastered with every companion change (see README.md for the list and the undo line). Extra arguments go to the script.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Apply-CompanionPatches.ps1" %*
pause
