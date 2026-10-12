@echo off
setlocal EnableExtensions DisableDelayedExpansion

set "ZONGSOFT_HOSTING_SOURCE=%~1"
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0pack.ps1"
set "result=%errorlevel%"

endlocal & exit /b %result%
