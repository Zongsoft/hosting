@echo off
setlocal EnableExtensions DisableDelayedExpansion

pushd "%~dp0" || exit /b 1
setlocal EnableDelayedExpansion
set quote="

for /F "delims=#" %%a in ('"prompt #$E# & echo on & for %%b in (1) do rem"') do set "ESC=%%a"
set "YELLOW=!ESC![93m"
set "GREEN=!ESC![92m"
set "RED=!ESC![91m"
set "RESET=!ESC![0m"

echo Create migration artifacts
echo(

set "prompt=Please enter the migration name(default:zongsoft): "
call :read_input
set "name=!input!"
if not defined name set "name=zongsoft"

set "prompt=Please enter the edition(optional): "
call :read_input
set "edition=!input!"

:version_input
set "prompt=Please enter the version number, version file or directory(!YELLOW!required!RESET!): "
call :read_input
if not defined input goto version_input
set "version=!input!"
call :quote_input
set "versionArgument=!argument!"

set "prompt=Please enter the platform(linux/windows, default:linux): "
call :read_input
set "platform=!input!"
if not defined platform set "platform=linux"

set "prompt=Please enter the architecture(x64/arm64, default:x64): "
call :read_input
set "architecture=!input!"
if not defined architecture set "architecture=x64"

set "prompt=Please enter the scheme(default:default): "
call :read_input
set "scheme=!input!"
if not defined scheme set "scheme=default"

set "migrationArguments="

:migration_input
set "finishInput="
set "prompt=Please enter a migration file path(!YELLOW!Enter to use all *.migration files!RESET!): "
if defined migrationArguments set "prompt=Please enter a migration file path(Enter to finish): "
call :read_input
if not defined input (
	if defined migrationArguments goto migrate
	set "input=*.migration"
	set "finishInput=1"
	echo !YELLOW!Using .deploy/$^(scheme^)/migration/$^(version^)/*.migration!RESET!
)

if "!input!"=="*" (
	echo !YELLOW!Enter *.migration explicitly, or leave the first path empty to select all migration files.!RESET!
	goto migration_input
)

if "!input:~-2!"=="/*" set "input=!input:~0,-1!*.migration"

set "directoryCheck=!input:/=!"
set "directoryCheck=!directoryCheck:\=!"
if "!directoryCheck!"=="!input!" set "input=.deploy/$(scheme)/migration/$(version)/!input!"
call :quote_input
set "migrationArguments=!migrationArguments! !argument!"

if defined finishInput goto migrate
goto migration_input

:migrate
dotnet-migrate                   ^
	--name:"!name!"              ^
	--edition:"!edition!"        ^
	--version:!versionArgument!  ^
	--platform:"!platform!"      ^
	--architecture:"!architecture!" ^
	--output:"."                 ^
	!migrationArguments!

set "migrateExitCode=!errorlevel!"
if "!migrateExitCode!"=="0" (
	echo !GREEN!Migration artifacts created successfully.!RESET!
) else (
	echo !RED!Migration artifact generation failed with exit code !migrateExitCode!.!RESET!
	pause
)

popd
endlocal & endlocal & exit /b %migrateExitCode%

REM Read and trim without CALL-expanding user data or losing literal exclamation marks.
:read_input
set "input="
set /p "input=!prompt!"
call :trim_input
if not defined input exit /b
if "!input:~0,1!"=="!quote!" if "!input:~-1!"=="!quote!" (
	set "input=!input:~1,-1!"
	call :trim_input
)
exit /b

:trim_input
if not defined input exit /b
if "!input:~0,1!"==" " (
	set "input=!input:~1!"
	goto trim_input
)
if "!input:~0,1!"=="	" (
	set "input=!input:~1!"
	goto trim_input
)

:trim_input_end
if not defined input exit /b
if "!input:~-1!"==" " (
	set "input=!input:~0,-1!"
	goto trim_input_end
)
if "!input:~-1!"=="	" (
	set "input=!input:~0,-1!"
	goto trim_input_end
)
exit /b

REM Double trailing backslashes before the closing quote for native Windows arguments.
:quote_input
set "argument=!input!"
set "tail=!input!"

:quote_input_end
if not defined tail goto quote_input_done
if "!tail:~-1!"=="\" (
	set "argument=!argument!\"
	set "tail=!tail:~0,-1!"
	goto quote_input_end
)

:quote_input_done
set "argument="!argument!""
exit /b
