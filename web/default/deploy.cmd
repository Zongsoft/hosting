@echo off

SET scheme=
SET /p scheme=Please enter the scheme name you want to deploy: 
if "%scheme%"=="" (SET scheme=default)

SET environment=%Environment%
SET /p environment=Please enter the environment name you want to deploy(%Environment%:[development^|test^|production]): 
if "%environment%"=="" (
	if "%Environment%"=="" (SET environment=development) else (SET environment=%Environment%)
)

SET debug=
SET /p debug=Do you want to turn on remote debug mode?(On/Off)
if "%debug%"=="" (SET debug=on)

SET platform=
if /i "%debug%"=="on" (SET platform=windows) else (SET platform=linux)

SET value=
SET /p value=Please enter the platform(windows/linux/mac) you want to deploy: 
if "%value%" neq "" (SET platform=%value%)

dotnet deploy                      ^
	-verbosity:quiet           ^
	-overwrite:latest          ^
	-host:web                  ^
	-site:default              ^
	-scheme:%scheme%           ^
	-environment:%environment% ^
	-debug:%debug%             ^
	-edition:Debug             ^
	-framework:net10.0         ^
	-platform:%platform%       ^
	-architecture:x64          ^
	.deploy                    ^
	..\\..\\.deploy\\%scheme%\\^$^(host^).deploy ^
	..\\..\\.deploy\\%scheme%\\^$^(site^).deploy
