@echo off

SET scheme=
SET /p scheme=Please enter the scheme name you want to deploy: 
if "%scheme%"=="" (SET scheme=default)

SET debug=
SET /p debug=Do you want to turn on remote debug mode?(On/Off)
if "%debug%"=="" (SET debug=on)

dotnet deploy                ^
	-verbosity:normal    ^
	-overwrite:newest    ^
	-host:terminal       ^
	-site:daemon         ^
	-scheme:%scheme%     ^
	-debug:%debug%       ^
	-edition:Debug       ^
	-framework:net8.0    ^
	-destination:bin/^$^(edition^)/^$^(framework^) ^
	.deploy                                        ^
	..\\.deploy\\%scheme%\\^$^(host^).deploy       ^
	..\\.deploy\\%scheme%\\^$^(site^).deploy
