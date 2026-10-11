@echo off
setlocal EnableExtensions DisableDelayedExpansion

set "ZONGSOFT_HOSTING_SOURCE=%~1"
set "ZONGSOFT_HOSTING_LOCAL_DEBUG="
if /i "%~2"=="--local-debug" set "ZONGSOFT_HOSTING_LOCAL_DEBUG=1"

"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0.shared.ps1" -Operation Deploy
set "result=%errorlevel%"

endlocal & exit /b %result%
