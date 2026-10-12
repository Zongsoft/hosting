@echo off
setlocal EnableExtensions DisableDelayedExpansion

"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0containerize.ps1" %*
set "result=%errorlevel%"

endlocal & exit /b %result%
