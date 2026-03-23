@echo off

SET /p platform=Please enter the platform(win/linux/osx) you want to publish: 
if "%platform%"=="" (SET platform=win)
if /i "%platform%"=="window" (SET platform=win)
if /i "%platform%"=="windows" (SET platform=win)

SET /p architecture=Please enter the architecture(x64/arm64) you want to publish: 
if "%architecture%"=="" (SET architecture=x64)

:version_label
SET version=
SET /p version=Please enter the version(format: major.minor.build.revision): 

if "%version%"=="" (
    echo Error: Version cannot be empty.
    goto version_label
)

SET edition=Debug
SET framework=net10.0
SET application=Zongsoft.Hosting.Terminal

vpk pack ^
	--packId %application%                  ^
	--packVersion %version%                 ^
	--framework %framework%^-%architecture% ^
	--channel %platform%                    ^
	--packDir bin\\%edition%\\%framework%   ^
	--outputDir publish\\%version%\\%platform%-%architecture%
