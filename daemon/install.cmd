@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"

net session >nul 2>nul
if errorlevel 1 (
	echo Requesting administrator privileges...
	powershell -Command "Start-Process -Verb RunAs -FilePath '%~f0' -WorkingDirectory '%~dp0'"
	exit /b
)

set /p SERVICE_NAME="Enter service name to install(default: zongsoft.daemon): "
if "%SERVICE_NAME%"=="" set SERVICE_NAME=zongsoft.daemon

set FOUND_COUNT=0
for %%f in (*.exe) do (
	set /a FOUND_COUNT+=1
	set "SERVICE_PATH=%cd%\%%f"
)

if !FOUND_COUNT! equ 0 (
	set /p EDITION="Enter the compilation edition(default: Debug): "
	if "!EDITION!"=="" set EDITION=Debug

	set /p FRAMEWORK="Enter the .NET framework(default: net10.0): "
	if "!FRAMEWORK!"=="" set FRAMEWORK=net10.0

	set FOUND_COUNT=0
	for %%f in (bin\!EDITION!\!FRAMEWORK!\*.exe) do (
		set /a FOUND_COUNT+=1
		set "SERVICE_PATH=%cd%\%%f"
	)

	if !FOUND_COUNT! equ 0 (
		echo [ERROR] No .exe file found in bin\!EDITION!\!FRAMEWORK!\
		pause
		exit /b 1
	) else if !FOUND_COUNT! gtr 1 (
		echo [ERROR] Multiple .exe files found in bin\!EDITION!\!FRAMEWORK!\:
		for %%f in (bin\!EDITION!\!FRAMEWORK!\*.exe) do echo   %cd%\%%f
		pause
		exit /b 1
	)
) else if !FOUND_COUNT! gtr 1 (
	echo [ERROR] Multiple .exe files found in current directory:
	for %%f in (*.exe) do echo   %cd%\%%f
	pause
	exit /b 1
)

echo.
echo The '%SERVICE_NAME%' service is installing...

REM 获取服务文件路径中的文件名(不含扩展名)
for %%i in ("!SERVICE_PATH!") do set "DESCRIPTION=%%~ni"

sc create "%SERVICE_NAME%" binPath="!SERVICE_PATH!" DisplayName="%SERVICE_NAME%" start=auto
if !ERRORLEVEL! equ 0 (
	sc description "%SERVICE_NAME%" "!DESCRIPTION!" >nul
	echo The '%SERVICE_NAME%' service has been successfully created.
	echo.

	set /p START="Start the service now?[yes/no] "
	if /i "!START!"=="" set START=yes
	if /i "!START!"=="yes" (
		sc start "%SERVICE_NAME%"
		if !ERRORLEVEL! equ 0 (
			echo The '%SERVICE_NAME%' service has been started.
		) else (
			echo [ERROR] Failed to start service, error code: !ERRORLEVEL!
			pause
		)
	)
) else (
	echo [ERROR] Failed to create service, error code: !ERRORLEVEL!
	pause
)
