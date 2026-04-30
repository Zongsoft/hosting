@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"

net session >nul 2>nul
if errorlevel 1 (
	echo Requesting administrator privileges...
	powershell -Command "Start-Process -Verb RunAs -FilePath '%~f0' -WorkingDirectory '%~dp0'"
	exit /b
)

set /p SERVICE_NAME="Enter service name to uninstall(default: zongsoft.daemon): "
if "%SERVICE_NAME%"=="" set SERVICE_NAME=zongsoft.daemon
echo.

sc query "%SERVICE_NAME%" >nul 2>nul
if errorlevel 1 (
	echo [ERROR] The '%SERVICE_NAME%' service does not exist.
	exit /b 1
)

sc query "%SERVICE_NAME%" | find "RUNNING" >nul
if !ERRORLEVEL! equ 0 (
	echo The '%SERVICE_NAME%' service is running, stop it now...
	sc stop "%SERVICE_NAME%" >nul
)

echo.
sc delete "%SERVICE_NAME%"
if !ERRORLEVEL! equ 0 (
	echo The '%SERVICE_NAME%' service has been successfully deleted.
) else (
	echo [ERROR] Failed to delete service, error code: !ERRORLEVEL!
	pause
)
