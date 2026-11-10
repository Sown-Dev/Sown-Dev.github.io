@echo off
rem Double-click: find new Pages sites, rebuild the list, commit and push.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0publish.ps1" %*
pause
