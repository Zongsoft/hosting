@echo off
setlocal EnableExtensions DisableDelayedExpansion

set "ZONGSOFT_HOSTING_SOURCE=%~1"
set "ZONGSOFT_HOSTING_LOCAL="
if /i "%~2"=="--local" set "ZONGSOFT_HOSTING_LOCAL=1"

"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0deploy.ps1"
set "result=%errorlevel%"

endlocal & exit /b %result%
