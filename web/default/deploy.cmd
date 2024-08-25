@echo off

SET scheme=
SET /p scheme=Please enter the scheme name you want to deploy: 
if "%scheme%"=="" (SET scheme=default)

SET debug=
SET /p debug=Do you want to turn on remote debug mode?(On/Off)
if "%debug%"=="" (SET debug=on)

dotnet deploy                ^
	-verbosity:quiet     ^
	-overwrite:latest    ^
	-host:web            ^
	-site:default        ^
	-scheme:%scheme%     ^
	-edition:Debug       ^
	-debug:%debug%       ^
	-framework:net8.0    ^
	.deploy              ^
	..\\..\\.deploy\\%scheme%\\^$^(host^).deploy ^
	..\\..\\.deploy\\%scheme%\\^$^(site^).deploy
