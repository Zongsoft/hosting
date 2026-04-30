@echo off
setlocal enabledelayedexpansion

set /p SERVICE_NAME="Enter service name to install(default: zongsoft.daemon): "
if "%SERVICE_NAME%"=="" set SERVICE_NAME=zongsoft.daemon
echo.

set FOUND_COUNT=0
for /f "delims=" %%f in ('dir /s /b *.exe 2^>nul') do (
	set /a FOUND_COUNT+=1
	set "SERVICE_PATH=%%f"
)

if !FOUND_COUNT! equ 0 (
	echo [ERROR] No .exe file found in current directory or subdirectories
	exit /b 1
) else if !FOUND_COUNT! gtr 1 (
	echo [ERROR] Multiple .exe files found:
	for /f "delims=" %%f in ('dir /s /b *.exe 2^>nul') do echo   %%f
	exit /b 1
)

echo.
echo Creating service "%SERVICE_NAME%" ...

sc create "%SERVICE_NAME%" binPath= "!SERVICE_PATH!" DisplayName= "%SERVICE_NAME%"
if !ERRORLEVEL! equ 0 (
	echo The '%SERVICE_NAME%' service has been successfully created.
) else (
	echo [ERROR] Failed to create service, error code: !ERRORLEVEL!
)
