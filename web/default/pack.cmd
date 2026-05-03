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
SET /p value=Please enter the edition you want to pack: 

SET compilation=
SET /p value=Please enter the compilation configuration(Debug/Release) you want to pack: 
if "%compilation%"=="" (SET compilation=Debug)

SET framework=
SET /p value=Please enter the framework(net10.0/net9.0/net8.0) you want to pack: 
if "%framework%"=="" (SET framework=net10.0)

SET platform=
SET /p value=Please enter the platform(windows/linux/mac) you want to pack: 
if "%platform%"=="" (SET platform=windows)

SET architecture=
SET /p value=Please enter the architecture(x64/arm64) you want to pack: 
if "%architecture%"=="" (SET architecture=x64)

dotnet-pack                           ^
	--name:Zongsoft.Web           ^
	--kind:fully                  ^
	--edition:%edition%           ^
	--version:%version%           ^
	--checksum:sha1               ^
	--compilation:%compilation%   ^
	--framework:%framework%       ^
	--platform:%platform%         ^
	--architecture:%architecture% ^
	--source:"D:/Zongsoft/hosting/web/default" ^
	--output:.                    ^
	mime                          ^
	appsettings.json              ^
	web*.config                   ^
	web*.option                   ^
	wwwroot                       ^
	plugins                       ^
	bin/$(compilation)/$(framework):~
