@echo off
setlocal EnableExtensions DisableDelayedExpansion
pushd "%~dp0" || exit /b 1

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

SET "format="
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
	popd
	endlocal & exit /b 1
)

SET edition=
SET /p "edition=Please enter the edition you want to pack: "

SET version=
SET /p "version=Please enter the version you want to pack: "

SET "environment=%Environment%"
SET /p "environment=Please enter the environment(development/test/production, default:development): "
if "%environment%"=="" (SET "environment=development")

SET compilation=
SET /p "compilation=Please enter the compilation configuration(Debug/Release, default:Release) you want to pack: "
if "%compilation%"=="" (SET compilation=Release)

SET architecture=
SET /p architecture=Please enter the architecture(x64/arm64):
if "%architecture%"=="" (SET architecture=x64)

SET "migration="
SET /p "migration=Please enter the migration input name or path(e.g. zongsoft; Enter to skip): "
if defined migration SET "migration=%migration:"=%"

dotnet-pack %format%              ^
	--name:zongsoft.terminal      ^
	--title:Zongsoft.Terminal       ^
	--edition:"%edition%"           ^
	--version:"%version%"           ^
	--compilation:"%compilation%"   ^
	--platform:"%platform%"         ^
	--architecture:"%architecture%" ^
	--migration:"%migration%"       ^
	--Environment:"%environment%"   ^
	--DOTNET_ENVIRONMENT:"%environment%" ^
	--daemon:disabled             ^
	--daemon-environments:Environment,DOTNET_ENVIRONMENT ^
	--exclude:**/logs/;           ^
	--output:.packages            ^
	bin/$(compilation)/$(framework):~

set "packExitCode=%errorlevel%"
if not "%packExitCode%"=="0" pause

popd
endlocal & exit /b %packExitCode%
