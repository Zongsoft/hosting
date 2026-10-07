@echo off
setlocal EnableExtensions DisableDelayedExpansion

REM Defaults are shared by prompts and the final tool arguments.
set "defaultName=zongsoft"
pushd "%~dp0" || exit /b 1
setlocal EnableDelayedExpansion
set quote="
set "name=!defaultName!"
set "edition="
set "version="
set "platform=linux"
set "architecture=x64"
set "scheme=default"
set "output=.migration"
set "migrationRoot=.deploy/$(scheme)/migration/$(version)"
call :initialize_style
call :write_banner

REM ---- Migration identity and target runtime ----
call :write_heading "1. Migration settings"
set "inputLabel=Migration name"
set "inputHint=Enter: !name!"
call :read_setting name

set "inputLabel=Edition"
set "inputHint=Optional. Enter: no edition."
call :read_setting edition

:version_input
set "inputLabel=Version"
set "inputHint=Required. Version number, version file or directory."
call :read_input
if not defined input (
	call :write_warning "Enter a version number, version file or directory."
	goto version_input
)
set "version=!input!"

set "inputLabel=Target platform"
set "inputHint=linux or windows. Enter: !platform!"
call :read_setting platform

set "inputLabel=Architecture"
set "inputHint=x64 or arm64. Enter: !architecture!"
call :read_setting architecture

set "inputLabel=Deployment scheme"
set "inputHint=Enter: !scheme!"
call :read_setting scheme

REM ---- Input patterns; preserve the existing directory and wildcard rules ----
call :write_heading "2. Migration inputs"
echo   !DIM!Add one file or pattern per line; leave the next line empty to finish.!RESET!
echo   !DIM!Bare filenames use !migrationRoot!/.!RESET!
echo   !DIM!Paths with / or \ remain relative to hosting, or absolute as entered.!RESET!
set "migrationArguments="
set "migrationCount=0"

:migration_input
set "finishInput="
set /a nextMigration=migrationCount+1
set "inputLabel=Migration input !nextMigration!"
set "inputHint=Enter: all *.migration files in the scheme/version directory."
if defined migrationArguments set "inputHint=Enter: finish input selection."
call :read_input
if not defined input (
	if defined migrationArguments goto migrate
	set "input=*.migration"
	set "finishInput=1"
	echo   !DIM![DEFAULT] Using !migrationRoot!/*.migration!RESET!
)
if "!input!"=="*" (
	call :write_warning "Use *.migration, or leave the first path empty to select all migration files."
	goto migration_input
)
if "!input:~-2!"=="/*" set "input=!input:~0,-1!*.migration"
set "directoryCheck=!input:/=!"
set "directoryCheck=!directoryCheck:\=!"
if "!directoryCheck!"=="!input!" set "input=!migrationRoot!/!input!"
call :quote_input
set "migrationArguments=!migrationArguments! !argument!"
set /a migrationCount+=1
if defined finishInput goto migrate
goto migration_input

REM ---- Execution: quote every option once and retain the tool's exit code ----
:migrate
set "options="
for %%o in (name edition version platform architecture scheme output) do (
	set "input=!%%o!"
	call :quote_input
	set "options=!options! --%%o:!argument!"
)
call :write_execution
dotnet-migrate !options! !migrationArguments!
set "migrateExitCode=!errorlevel!"
call :write_heading "Result"
if "!migrateExitCode!"=="0" (
	echo   !GREEN![OK] Migration artifacts created successfully.!RESET!
) else (
	echo   !RED![ERROR] Migration artifact generation failed with exit code !migrateExitCode!.!RESET!
	echo   !DIM!See the tool error details above.!RESET!
	echo(
	echo   !DIM!Press any key to finish.!RESET!
	pause >nul
)
popd
endlocal & endlocal & exit /b %migrateExitCode%

REM ---- UI helpers; CALL arguments are fixed labels or names, never user data ----
:initialize_style
for %%c in (HEADING CYAN GREEN YELLOW RED DIM RESET CURSOR_SAVE CURSOR_RESTORE CURSOR_NEXT_LINE CURSOR_PREVIOUS_LINE CURSOR_INDENT) do set "%%c="
REM 0: console, 1: redirected input, 2: redirected output.
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoLogo -NoProfile -Command "if([Console]::IsOutputRedirected) { exit 2 }; if([Console]::IsInputRedirected) { exit 1 }; exit 0"
set "consoleMode=!errorlevel!"
if "!consoleMode!"=="2" exit /b 0
for /f "delims=#" %%a in ('"prompt #$E# & echo on & for %%b in (1) do rem"') do set "ESC=%%a"
REM Cursor positioning also applies when NO_COLOR disables colors.
if "!consoleMode!"=="0" (
	set "CURSOR_SAVE=!ESC![s"
	set "CURSOR_RESTORE=!ESC![u"
	set "CURSOR_NEXT_LINE=!ESC![1E"
	set "CURSOR_PREVIOUS_LINE=!ESC![1F"
	set "CURSOR_INDENT=!ESC![3G"
)
if defined NO_COLOR exit /b 0
set "HEADING=!ESC![1;96m"
set "CYAN=!ESC![96m"
set "GREEN=!ESC![92m"
set "YELLOW=!ESC![93m"
set "RED=!ESC![91m"
set "DIM=!ESC![90m"
set "RESET=!ESC![0m"
exit /b 0

:write_banner
echo(
echo   !HEADING!MIGRATION ARTIFACTS!RESET!
echo   !DIM!!defaultName!  /  dotnet-migrate!RESET!
echo   !DIM!------------------------------------------------------------!RESET!
exit /b 0

:write_heading
echo(
echo   !HEADING!%~1!RESET!
echo   !DIM!------------------------------------------------------------!RESET!
exit /b 0

:write_hint
if defined inputHint echo   !DIM!!inputHint!!RESET!
exit /b 0

REM Keep the hint below the field while reading at the end of its label.
:write_input_prompt
if not defined CURSOR_SAVE (
	echo   !CYAN!!inputLabel!:!RESET!
	exit /b 0
)
<nul set /p "=!CURSOR_NEXT_LINE!!CURSOR_PREVIOUS_LINE!"
<nul set /p "=!CURSOR_INDENT!!CYAN!!inputLabel!: !RESET!!CURSOR_SAVE!!CURSOR_NEXT_LINE!"
<nul set /p "=!CURSOR_INDENT!!DIM!!inputHint!!RESET!!CURSOR_RESTORE!"
exit /b 0

:finish_input
if defined CURSOR_NEXT_LINE (
	<nul set /p "=!CURSOR_NEXT_LINE!"
) else (
	call :write_hint
)
echo(
exit /b 0

:write_warning
echo   !YELLOW![WARN] %~1!RESET!
exit /b 0

:write_execution
call :write_heading "Execution"
echo   !DIM!Name    :!RESET! !name!
if defined edition echo   !DIM!Edition :!RESET! !edition!
echo   !DIM!Version :!RESET! !version!
echo   !DIM!Runtime :!RESET! !platform!-!architecture!
echo   !DIM!Scheme  :!RESET! !scheme!
echo   !DIM!Output  :!RESET! !output!
echo   !DIM!Inputs  :!RESET! !migrationCount! pattern(s)
echo(
exit /b 0

:read_setting
call :read_input
if defined input for %%s in (%~1) do set "%%s=!input!"
exit /b 0

REM Input helpers do not CALL-expand values; %, ! and metacharacters remain literal.
:read_input
set "input="
call :write_input_prompt
set /p "input="
call :finish_input
call :trim_input
if not defined input exit /b 0
if "!input:~0,1!"=="!quote!" if "!input:~-1!"=="!quote!" (
	set "input=!input:~1,-1!"
	call :trim_input
)
exit /b 0

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

:quote_input
REM Double trailing backslashes before adding quotes around a Windows argument.
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
