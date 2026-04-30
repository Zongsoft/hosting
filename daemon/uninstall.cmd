@echo off
setlocal enabledelayedexpansion

set /p SERVICE_NAME="Enter service name to uninstall(default: zongsoft.daemon): "
if "%SERVICE_NAME%"=="" set SERVICE_NAME=zongsoft.daemon
echo.

sc delete "%SERVICE_NAME%"
if !ERRORLEVEL! equ 0 (
	echo The '%SERVICE_NAME%' service has been successfully deleted.
) else (
	echo [ERROR] Failed to delete service, error code: !ERRORLEVEL!
)
