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
set "DARK_GRAY=%ESC%[37m"

REM 定义文字样式代码
set "ITALIC=%ESC%[3m"

REM 定义光标控制代码
set "CURSOR_SAVE=%ESC%[s"
set "CURSOR_RESTORE=%ESC%[u"
set "CURSOR_NEXT_LINE=%ESC%[1E"
set "CURSOR_PREVIOUS_LINE=%ESC%[1F"

set "RESET=%ESC%[0m"

SET scheme=
SET /p scheme=Please enter the scheme name you want to deploy: 
if "%scheme%"=="" (SET scheme=default)

SET environment=%Environment%
SET /p value=Please enter the environment name you want to pack%ITALIC%(%GREEN%%Environment%%RESET%:%ITALIC%%DARK_YELLOW%[development/test/production]%RESET%): 
if "%value%"=="" (
	if "%environment%"=="" (SET environment=development)
)

SET debug=
SET /p debug=Do you want to turn on remote debug mode?%ITALIC%%DARK_YELLOW%(On/Off)%RESET%
if "%debug%"=="" (SET debug=on)

SET compilation=
if /i "%debug%"=="on" (SET compilation=Debug) else (SET compilation=Release)

SET platform=
if /i "%debug%"=="on" (SET platform=windows) else (SET platform=linux)

SET /p value=Please enter the platform%ITALIC%%DARK_YELLOW%(windows/linux/mac)%RESET% you want to deploy: 
if "%value%" neq "" (SET platform=%value%)

SET architecture=
SET /p architecture=Please enter the architecture%ITALIC%%DARK_YELLOW%(x64/x32/arm64)%RESET% you want to deploy:
if "%architecture%"=="" (SET architecture=x64)

SET framework=
SET /p framework=Please enter the framework%ITALIC%%DARK_YELLOW%(net10.0/net9.0/net8.0)%RESET% you want to deploy: 
if "%framework%"=="" (SET framework=net10.0)

dotnet cake             ^
	--edition=%compilation% ^
	--platform=%platform%   ^
	--architecture=%architecture% ^
	--framework=%framework%

dotnet deploy                      ^
	--verbosity:normal            ^
	--overwrite:newest            ^
	--host:daemon                 ^
	--site:daemon                 ^
	--scheme:%scheme%             ^
	--environment:%environment%   ^
	--debug:%debug%               ^
	--edition:%compilation%       ^
	--framework:%framework%       ^
	--platform:%platform%         ^
	--architecture:%architecture% ^
	--destination:bin/$(edition)/$(framework) ^
	.deploy                                   ^
	../.deploy/%scheme%/$(host).deploy        ^
	../.deploy/%scheme%/$(site).deploy

echo.

:format_label

echo.
echo %CYAN%Do you need to create an installer for the deployed application?%RESET%
<nul SET /p "=%CURSOR_NEXT_LINE%%CURSOR_PREVIOUS_LINE%"
<nul SET /p "=%GREEN%If you need to package it, please enter the installer format%ITALIC%%DARK_YELLOW%(deb/rpm/tar):%RESET%%CURSOR_SAVE%%CURSOR_NEXT_LINE%"
SET /p format=%ITALIC%%MAGENTA%TIPS:%RESET%%ITALIC% Enter '%ITALIC%%BLUE%exit%RESET%%ITALIC%' or '%ITALIC%%BLUE%quit%RESET%%ITALIC%' to exit.%RESET%%CURSOR_RESTORE%
<nul SET /p "=%CURSOR_NEXT_LINE%"

if "%format%"=="" goto format_label
if /i "%format%"=="exit" exit /b 1
if /i "%format%"=="quit" exit /b 1

if /i "%format%"=="tar" (
	SET platform=linux
) else if /i "%format%"=="deb" (
	SET platform=linux
) else if /i "%format%"=="rpm" (
	SET platform=linux
) else (
	echo %DARK_RED%Error: %RED%Unsupported package format '%DARK_YELLOW%%format%%RED%'.%RESET%
	SET format=
	goto format_label
)

:version_label

SET version=
SET /p version=Please enter the version you want to pack%ITALIC%%DARK_YELLOW%(major.minor.patch%DARK_GRAY%.revision%DARK_YELLOW%)%RESET%: 

if "%version%"=="" (
	echo %DARK_RED%Error: %RED%The version cannot be empty.%RESET%
	echo %ITALIC%%MAGENTA%TIPS:%RESET%%ITALIC% Enter '%ITALIC%%BLUE%exit%RESET%%ITALIC%' or '%ITALIC%%BLUE%quit%RESET%%ITALIC%' to exit.%RESET%

	goto version_label
)

if /i "%version%"=="exit" exit /b 0
if /i "%version%"=="quit" exit /b 0

SET edition=
SET /p edition=Please enter the edition you want to pack: 

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
	--exclude:**/logs/;           ^
	bin/$(compilation)/$(framework):~
