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

:version_label

SET version=
SET /p version=Please enter the version you want to pack: 

if "%version%"=="" (
	echo %DARK_RED%Error: %RED%The version cannot be empty.%RESET%
	echo %DARK_YELLOW%Note: %CYAN%To exit, please enter exit.%RESET%

	goto version_label
)

if /i "%version%"=="exit" exit /b 0

SET edition=
SET /p edition=Please enter the edition you want to pack: 

SET environment=%Environment%
SET /p value=Please enter the environment name you want to pack(%Environment%:[development/test/production]): 
if "%value%"=="" (
	if "%environment%"=="" (SET environment=development)
)

SET compilation=
SET /p compilation=Please enter the compilation configuration(Debug/Release) you want to pack: 
if "%compilation%"=="" (SET compilation=Debug)

SET framework=
SET /p framework=Please enter the framework(net10.0/net9.0/net8.0) you want to pack: 
if "%framework%"=="" (SET framework=net10.0)

SET architecture=
SET /p architecture=Please enter the architecture(x64/arm64) you want to pack: 
if "%architecture%"=="" (SET architecture=x64)

SET /p format=Please enter the packaging format(tar/deb/rpm) you want to pack:
if "%format%"=="" (SET format=tar)

if /i "%format%"=="tar" (
	SET platform=linux
) else if /i "%format%"=="deb" (
	SET platform=linux
) else if /i "%format%"=="rpm" (
	SET platform=linux
) else (
	echo %DARK_RED%Error: %RED%Unsupported package format '%format%'.%RESET%
	pause
	exit /b 1
)

dotnet-pack %format%              ^
	--name:Zongsoft.Daemon        ^
	--edition:%edition%           ^
	--version:%version%           ^
	--compilation:%compilation%   ^
	--framework:%framework%       ^
	--platform:%platform%         ^
	--architecture:%architecture% ^
	--Environment:%environment%   ^
	--daemon-environments:Environment ^
	--exclude:logs/;              ^
	--source:"D:\\Zongsoft\\hosting\\daemon\\bin\\$(compilation)\\$(framework)" ^
	--output:../../../
