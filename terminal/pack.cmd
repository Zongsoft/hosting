@echo off

:platform_label
SET /p platform=Please enter the platform(win/linux/osx) you want to publish: 
if "%platform%"=="" (SET platform=win)
if /i "%platform%"=="window" (SET platform=win)
if /i "%platform%"=="windows" (SET platform=win)
if /i "%platform%"=="osx" (
	echo Error: The '%platform%' operating system platform is not supported.
	goto platform_label
)

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
SET organization=Zongsoft

if "%platform%"=="linux" (
	vpk [linux] pack ^
		--packId %application%                     ^
		--packVersion %version%                    ^
		--packAuthors %organization%               ^
		--mainExe %application%.exe                ^
		--runtime %platform%-%architecture%^       ^
		--channel %platform%                       ^
		--packDir bin\\%edition%\\%framework%      ^
		--outputDir publish\\%version%\\%platform%-%architecture%
) else (
	vpk pack ^
		--packId %application%                     ^
		--packVersion %version%                    ^
		--packAuthors %organization%               ^
		--framework %framework%-%architecture%-sdk ^
		--channel %platform%                       ^
		--packDir bin\\%edition%\\%framework%      ^
		--outputDir publish\\%version%\\%platform%-%architecture%
)
