@echo off

SET scheme=
SET /p scheme=Please enter the scheme name you want to deploy: 
if "%scheme%"=="" (SET scheme=default)

SET debug=
SET /p debug=Do you want to turn on remote debug mode?(On/Off)
if "%debug%"=="" (SET debug=on)

SET platform=
if /i "%debug%"=="on" (SET platform=windows) else (SET platform=linux)

SET value=
SET /p value=Please enter the platform(windows/linux/mac) you want to deploy: 
if "%value%" neq "" (SET platform=%value%)

dotnet deploy                ^
	-verbosity:quiet     ^
	-overwrite:latest    ^
	-host:web            ^
	-site:default        ^
	-scheme:%scheme%     ^
	-debug:%debug%       ^
	-edition:Debug       ^
	-framework:net9.0    ^
	-platform:%platform% ^
	-architecture:x64    ^
	.deploy              ^
	..\\..\\.deploy\\%scheme%\\^$^(host^).deploy ^
	..\\..\\.deploy\\%scheme%\\^$^(site^).deploy
