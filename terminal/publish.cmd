@echo off

REM 获取ESC字符
for /F "delims=#" %%a in ('"prompt #$E# & echo on & for %%b in (1) do rem"') do set "ESC=%%a"

REM 定义颜色代码
set "RED=%ESC%[91m"
set "GREEN=%ESC%[92m"
set "YELLOW=%ESC%[93m"
set "BLUE=%ESC%[94m"
set "MAGENTA=%ESC%[95m"
set "CYAN=%ESC%[96m"

set "DARK_RED=%ESC%[31m"
set "DARK_GREEN=%ESC%[32m"
set "DARK_YELLOW=%ESC%[33m"
set "DARK_BLUE=%ESC%[34m"
set "DARK_MAGENTA=%ESC%[35m"
set "DARK_CYAN=%ESC%[36m"

set "RESET=%ESC%[0m"

SET server=
SET /p server=Please enter the server you want to publish:
if "%server%"=="" (SET server=http://127.0.0.1:9000)

SET access=
SET /p access=Please enter the access-key you want to publish:
if "%access%"=="" (SET access=rustfsadmin)

SET secret=
SET /p secret=Please enter the secret-key you want to publish:
if "%secret%"=="" (SET secret=rustfsadmin)

:version_label

SET version=
SET /p version=Please enter the version you want to publish:

if "%version%"=="" (
	echo %DARK_RED%Error: %RED%The version cannot be empty.%RESET%
	echo %DARK_YELLOW%Note: %CYAN%To exit, please enter exit.%RESET%

	goto version_label
)

if /i "%version%"=="exit" exit /b 0

SET platform=
SET /p platform=Please enter the platform(windows/linux/mac) you want to publish:
if "%platform%"=="" (
	SET platform=win
) else if /i "%platform%"=="windows" (
	SET platform=win
)

SET architecture=
SET /p architecture=Please enter the architecture(x64/arm64) you want to publish:
if "%architecture%"=="" (SET architecture=x64)

SET edition=
SET /p edition=Please enter the edition you want to publish:
if "%edition%"=="" (
	SET "file_path=Zongsoft.Terminal@%version%_%platform%-%architecture%"
) else (
	SET "file_path=Zongsoft.Terminal(%edition%)@%version%_%platform%-%architecture%"
)

dotnet-pack publish                           ^
	--channel:amazon.s3                       ^
	--server:%server%                         ^
	--access:%access%                         ^
	--secret:%secret%                         ^
	--destination:upgrading/releases/terminal ^
	%file_path%
