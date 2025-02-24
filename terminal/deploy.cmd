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
	-verbosity:normal    ^
	-overwrite:newest    ^
	-host:terminal       ^
	-site:daemon         ^
	-scheme:%scheme%     ^
	-debug:%debug%       ^
	-edition:Debug       ^
	-framework:net9.0    ^
	-platform:%platform% ^
	-architecture:x64    ^
	-destination:bin/^$^(edition^)/^$^(framework^) ^
	.deploy                                        ^
	..\\.deploy\\%scheme%\\^$^(host^).deploy       ^
	..\\.deploy\\%scheme%\\^$^(site^).deploy
