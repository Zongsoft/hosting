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

SET compilation=
if /i "%debug%"=="on" (SET compilation=Debug) else (SET compilation=Release)

SET platform=
if /i "%debug%"=="on" (SET platform=windows) else (SET platform=linux)

SET value=
SET /p value=Please enter the platform(windows/linux/mac) you want to deploy: 
if "%value%" neq "" (SET platform=%value%)

SET architecture=
SET /p architecture=Please enter the architecture(x64/x32/arm64) you want to deploy:
if "%architecture%"=="" (SET architecture=x64)

SET framework=
SET /p framework=Please enter the framework(net10.0/net9.0/net8.0) you want to deploy: 
if "%framework%"=="" (SET framework=net10.0)

dotnet cake             ^
	--edition=%compilation% ^
	--platform=%platform%   ^
	--architecture=%architecture%

dotnet deploy                      ^
	--verbosity:normal            ^
	--overwrite:newest            ^
	--host:terminal               ^
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
