@echo off
setlocal EnableExtensions DisableDelayedExpansion

REM Entry arguments remain literal; only interactive values use delayed expansion.
set "defaultName=zongsoft"
set "requested=%~1"
set "second=%~2"
set "operation="
set "directPrefix="
set "manifest="
set "refresh="
if /i "%~1"=="--refresh" if "%~2"=="" (
	set "requested="
	set "refresh=--refresh"
)

pushd "%~dp0" || exit /b 1
setlocal EnableDelayedExpansion
set quote="
call :initialize_style
call :write_banner

for %%o in (plan make run) do if /i "!requested!"=="%%o" set "operation=%%o"
if defined operation if defined second goto direct_arguments
if defined requested if not defined operation (
	if /i "!requested:~-10!"==".container" (
		set "operation=make"
		set "directPrefix=make"
		goto direct_arguments
	)
	echo   !RED![ERROR] Unknown operation.!RESET!
	echo   !DIM!Usage: containerize.cmd [plan ^| make ^| run] [inputs and options]!RESET!
	set "containerizeExitCode=2"
	goto exit_script
)

REM ---- Operation selection ----
set "source=."
set "output=.containerized"
set "componentArguments="
for %%o in (name tag version architecture distribution engine bootstrap imaging migration) do set "%%o="

:operation_menu
if not defined operation (
	set "inputLabel=Operation"
	set "inputHint=Choose what to create or verify."
	set "menuValues=full;plan;make;run"
	set "menuLabels=Create complete delivery;Plan editable .container only;Make delivery from an existing .container;Run an existing container delivery"
	set "menuDefault=full"
	call :select_setting operation
	if errorlevel 1 goto selection_cancelled
)
if /i "!operation!"=="make" goto manifest_input
if /i "!operation!"=="run" goto manifest_input

REM ---- New delivery: identity, platform and optional migrations ----
set "name=!defaultName!"
set "tag="
set "version="
set "architecture=x64"
set "distribution=debian@13"
set "engine=auto"
set "bootstrap=offline"
set "imaging=offline"
set "migration="
call :write_heading "1. Delivery settings"

set "inputLabel=Application name"
set "inputHint=Enter: !name!"
call :read_setting name

set "inputLabel=Build tag"
set "inputHint=Optional. Enter: no tag."
call :read_setting tag

set "inputLabel=Release version"
set "inputHint=Enter: automatic date version."
call :read_setting version

set "inputLabel=Linux distribution"
set "inputHint=Default: !distribution!"
set "menuValues=ubuntu@22.04;debian@12;debian@13;rhel@9;rocky@9;almalinux@9"
set "menuLabels=Ubuntu 22.04 LTS;Debian 12;Debian 13;RHEL 9;Rocky Linux 9;AlmaLinux 9"
set "menuDefault=!distribution!"
call :select_setting distribution
if errorlevel 1 goto selection_cancelled

set "inputLabel=Architecture"
set "inputHint=Default: !architecture!"
set "menuValues=x64;arm64"
set "menuLabels=x64;ARM64"
set "menuDefault=!architecture!"
call :select_setting architecture
if errorlevel 1 goto selection_cancelled

set "inputLabel=Build engine"
set "inputHint=Default: !engine!"
set "menuValues=auto;docker;podman"
set "menuLabels=Automatic;Docker;Podman"
set "menuDefault=!engine!"
call :select_setting engine
if errorlevel 1 goto selection_cancelled

set "inputLabel=Bootstrap delivery"
set "inputHint=Engine dependencies. Default: !bootstrap!"
set "menuValues=online;offline"
set "menuLabels=Online;Offline"
set "menuDefault=!bootstrap!"
call :select_setting bootstrap
if errorlevel 1 goto selection_cancelled

set "inputLabel=Image delivery"
set "inputHint=Container images. Default: !imaging!"
set "menuValues=online;offline"
set "menuLabels=Online;Offline"
set "menuDefault=!imaging!"
call :select_setting imaging
if errorlevel 1 goto selection_cancelled

:migration_menu
set "inputLabel=Migration directory"
set "inputHint=Default: no migrations."
set "menuValues=none;.migration;manual"
set "menuLabels=No migrations (default);.migration;Enter a migration directory manually"
set "menuDefault=none"
call :select_option
if errorlevel 1 goto selection_cancelled
if "!input!"=="none" set "input="
if "!input!"=="manual" (
	set "inputLabel=Migration path"
	set "inputHint=Enter: no migrations. Esc: return to directory selection."
	call :read_input_escape
	if errorlevel 2 goto migration_menu
	if errorlevel 1 goto selection_cancelled
)
set "migration=!input!"

REM ---- Components or one existing manifest ----
call :write_heading "2. Delivery inputs"
echo   !DIM!Add one component per line; leave the next line empty to finish.!RESET!
echo   !DIM!Examples: redis, daemon, web/default, or an installation package.!RESET!
echo   !DIM!An existing .container file must be used by itself.!RESET!
set "componentCount=0"

:component_input
set /a nextComponent=componentCount+1
set "inputLabel=Component !nextComponent!"
set "inputHint=Template, package file/directory, or an existing .container file."
if defined componentArguments set "inputHint=Enter: finish component selection."
call :read_input
if not defined input (
	if defined componentArguments goto containerize
	call :write_warning "Add at least one component or select a manifest."
	goto component_input
)
if /i "!input:~-10!"==".container" (
	if defined componentArguments (
		call :write_warning "A .container file must be used by itself."
		goto component_input
	)
	set "manifest=!input!"
	goto containerize
)
call :quote_input
set "componentArguments=!componentArguments! !argument!"
set /a componentCount+=1
goto component_input

REM ---- Saved delivery selection; filenames may contain ! and menu delimiters ----
:manifest_input
set "fileExtension=.container"
if /i "!operation!"=="run" set "fileExtension=.tar.gz"
setlocal DisableDelayedExpansion
set "menuValues="
set "menuLabels="
set "manifestCount=0"
for /f "eol=| delims=" %%f in ('dir /b /a-d /on "%output%\*%fileExtension%" 2^>nul') do (
	set "manifestFile=%%f"
	call :append_manifest
)
set "menuValues=%menuValues%manual"
set "menuLabel.manual=Enter a %fileExtension% path manually"
set "menuDefault=1"
if "%manifestCount%"=="0" set "menuDefault=manual"
setlocal EnableDelayedExpansion
call :write_heading "1. Saved delivery"
set "inputLabel=Existing !fileExtension! file"
set "inputHint=Folder: !output!. Esc: return to operation selection."
call :select_option
if errorlevel 1 goto manifest_operation_back
if "!input!"=="manual" goto manifest_path
for %%n in (!input!) do set "manifest=!manifest.%%n!"
goto manifest_version

:manifest_operation_back
endlocal & endlocal & set "operation=" & goto operation_menu

:manifest_path
set "inputLabel=Delivery file path"
set "inputHint=Choose a !fileExtension! file. Esc: return to file selection."
call :read_input_escape
if errorlevel 2 goto manifest_path_back
if errorlevel 1 goto selection_cancelled
if not defined input goto manifest_path
if /i "!operation!"=="make" if /i not "!input:~-10!"==".container" (
	call :write_warning "Choose a .container file."
	goto manifest_path
)
if /i "!operation!"=="run" if /i not "!input:~-7!"==".tar.gz" (
	call :write_warning "Choose a .tar.gz file."
	goto manifest_path
)
set "manifest=!input!"
goto manifest_version

:manifest_path_back
endlocal & endlocal & goto manifest_input

:manifest_version
if /i "!operation!"=="run" goto delivery_run
set "inputLabel=New release version"
set "inputHint=Enter: keep the manifest version."
call :read_setting version

REM ---- Execution: retain tool output and its original exit code ----
:containerize
set "options="
set "optionNames=name tag version architecture distribution engine bootstrap imaging source output migration"
if defined manifest set "optionNames=version engine source output"
for %%o in (!optionNames!) do (
	set "input=!%%o!"
	if defined input (
		call :quote_input
		set "options=!options! --%%o:!argument!"
	)
)
set "buildArguments=!componentArguments!"
if defined manifest (
	set "input=!manifest!"
	call :quote_input
	set "buildArguments=!argument!"
)
set "subcommand=!operation!"
if /i "!subcommand!"=="full" set "subcommand="
call :write_execution
if defined refresh if /i not "!operation!"=="plan" (
	echo   !YELLOW![REFRESH] Preparing new public runtime environments.!RESET!
	echo(
	set "options=!options! --refresh"
)
dotnet-containerize !subcommand! !options! !buildArguments!
set "containerizeExitCode=!errorlevel!"
goto report_result

:delivery_run
set "input=!manifest!"
call :quote_input
call :write_execution
dotnet-containerize run !argument!
set "containerizeExitCode=!errorlevel!"
goto report_result

:direct_arguments
call :write_execution
setlocal DisableDelayedExpansion
if /i "%operation%"=="run" (
	dotnet-containerize %*
) else (
	dotnet-containerize %directPrefix% %* --source:. --output:.containerized
)
set "directExitCode=%errorlevel%"
endlocal & set "containerizeExitCode=%directExitCode%"
goto report_result

:report_result
if /i "!operation!"=="run" if "!containerizeExitCode!"=="0" goto exit_script
call :write_heading "Result"
if "!containerizeExitCode!"=="0" (
	if /i "!operation!"=="plan" (
		echo   !GREEN![OK] Plan completed successfully.!RESET!
		echo   !DIM!Editable .container created. Edit it, then run:!RESET!
		echo   !CYAN!containerize.cmd make FILE.container!RESET!
	) else (
		echo   !GREEN![OK] Make completed successfully.!RESET!
		echo   !DIM!Container delivery artifacts and .container manifest created.!RESET!
	)
) else (
	echo   !RED![ERROR] Container operation failed with exit code !containerizeExitCode!.!RESET!
	echo   !DIM!See the tool error details above.!RESET!
)
echo(
echo   !DIM!Press any key to finish.!RESET!
pause >nul

:exit_script
popd
endlocal & endlocal & exit /b %containerizeExitCode%

:selection_cancelled
echo(
echo   !YELLOW![CANCELLED] Selection cancelled or unavailable; no build started.!RESET!
set "containerizeExitCode=2"
goto exit_script

REM ---- Small UI helpers; arguments are fixed labels or setting names, never user data ----
:initialize_style
set "uiColor="
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
set "uiColor=1"
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
echo   !HEADING!CONTAINER DELIVERY!RESET!
echo   !DIM!!defaultName!  /  plan - make - run!RESET!
echo   !DIM!------------------------------------------------------------!RESET!
exit /b 0

:write_heading
echo(
echo   !HEADING!%~1!RESET!
echo   !DIM!------------------------------------------------------------!RESET!
exit /b 0

:write_prompt
echo   !CYAN!!inputLabel!!RESET!

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
echo   !DIM!Operation : !operation!!RESET!
if defined manifest echo   !DIM!Input     : !manifest!!RESET!
echo(
exit /b 0

:read_setting
call :read_input
if defined input for %%s in (%~1) do set "%%s=!input!"
exit /b 0

:select_setting
call :select_option
if errorlevel 1 exit /b 1
for %%s in (%~1) do set "%%s=!input!"
exit /b 0

REM Called with delayed expansion disabled; keep filenames literal.
:append_manifest
set /a manifestCount+=1
set "manifest.%manifestCount%=%output%\%manifestFile%"
set "menuLabel.%manifestCount%=%manifestFile%"
set "menuValues=%menuValues%%manifestCount%;"
exit /b 0

REM Arrow menu: 10+ is a row, 2 is cancel, 3 requests the redirected-input fallback.
:select_option
call :write_prompt
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoLogo -NoProfile -Command ^
	"$ErrorActionPreference = 'Stop';" ^
	"$values = $env:menuValues.Split(';');" ^
	"$labels = @(if($env:menuLabels) { $env:menuLabels.Split(';') } else { $values | ForEach-Object { [Environment]::GetEnvironmentVariable('menuLabel.' + $_) } });" ^
	"if([Console]::IsInputRedirected -or [Console]::IsOutputRedirected) {" ^
		"for($i = 0; $i -lt $labels.Length; $i++) { [Console]::WriteLine(('    {0}. {1}' -f ($i + 1), $labels[$i])); }; exit 3;" ^
	"};" ^
	"$index = [Math]::Max(0, [Array]::IndexOf($values, $env:menuDefault));" ^
	"$color = [Console]::ForegroundColor; $background = [Console]::BackgroundColor;" ^
	"$cursor = [Console]::CursorVisible; $useColor = $env:uiColor -eq '1';" ^
	"$choice = 2; $top = -1;" ^
	"try {" ^
		"if($useColor) { [Console]::ForegroundColor = 'DarkGray'; };" ^
		"[Console]::WriteLine('    Up/Down: move   Enter: confirm   Esc: back/cancel');" ^
		"if($useColor) { [Console]::ForegroundColor = $color; };" ^
		"for($i = 0; $i -lt $labels.Length; $i++) { [Console]::WriteLine(''); };" ^
		"$top = [Console]::CursorTop - $labels.Length; [Console]::CursorVisible = $false; $done = $false;" ^
		"while(-not $done) {" ^
			"[Console]::SetCursorPosition(0, $top); $width = [Math]::Max(1, [Console]::BufferWidth - 1);" ^
			"for($i = 0; $i -lt $labels.Length; $i++) {" ^
				"$marker = '  ';" ^
				"if($useColor) { [Console]::ForegroundColor = $color; [Console]::BackgroundColor = $background; };" ^
				"if($i -eq $index) { $marker = '> '; if($useColor) { [Console]::ForegroundColor = 'White'; [Console]::BackgroundColor = 'DarkCyan'; }; };" ^
				"$line = ('    {0}{1}. {2}' -f $marker, ($i + 1), $labels[$i]);" ^
				"if($line.Length -gt $width) { $line = $line.Substring(0, $width); }; [Console]::WriteLine($line.PadRight($width));" ^
			"};" ^
			"if($useColor) { [Console]::ForegroundColor = $color; [Console]::BackgroundColor = $background; };" ^
			"switch([Console]::ReadKey($true).Key) {" ^
				"'UpArrow' { $index = ($index + $labels.Length - 1) %% $labels.Length; }" ^
				"'DownArrow' { $index = ($index + 1) %% $labels.Length; }" ^
				"'Home' { $index = 0; } 'End' { $index = $labels.Length - 1; }" ^
				"'Enter' { $choice = $index + 10; $done = $true; } 'Escape' { $done = $true; }" ^
			"};" ^
		"};" ^
	"} catch { [Console]::Error.WriteLine($_.Exception.Message); }" ^
	"finally {" ^
		"if($useColor) { [Console]::ForegroundColor = $color; [Console]::BackgroundColor = $background; };" ^
		"[Console]::CursorVisible = $cursor;" ^
		"if($top -ge 0) { [Console]::SetCursorPosition(0, $top + $labels.Length); };" ^
	"}; exit $choice"
set "menuExitCode=!errorlevel!"
if "!menuExitCode!"=="3" goto select_text
echo(
if !menuExitCode! lss 10 exit /b 1
set /a menuIndex=menuExitCode-9
set "input="
for %%v in (%menuValues:;= %) do (
	set /a menuIndex-=1
	if "!menuIndex!"=="0" set "input=%%v"
)
if not defined input exit /b 1
exit /b 0

REM Number/value selection for pipes and input files returns the same default as Enter.
:select_text
set "inputLabel=Option"
set "inputHint=Number or listed value. Enter: !menuDefault!"
call :read_input
if not defined input set "input=!menuDefault!"
set "menuChoice="
set "menuIndex=0"
for %%v in (%menuValues:;= %) do (
	set /a menuIndex+=1
	if /i "!input!"=="%%v" set "menuChoice=%%v"
	if "!input!"=="!menuIndex!" set "menuChoice=%%v"
)
if not defined menuChoice (
	call :write_warning "Invalid selection. Choose one of the listed options."
	goto select_text
)
set "input=!menuChoice!"
exit /b 0

REM Manual paths share normalization with ordinary input; Escape returns code 2.
:read_input_escape
set "input="
set "manualInputFile=!TEMP!\containerize-input-!RANDOM!-!RANDOM!.tmp"
call :write_input_prompt
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoLogo -NoProfile -Command ^
	"$ErrorActionPreference = 'Stop';" ^
	"if([Console]::IsInputRedirected -or [Console]::IsOutputRedirected) { exit 3; };" ^
	"$buffer = [System.Text.StringBuilder]::new();" ^
	"while($true) {" ^
		"$key = [Console]::ReadKey($true);" ^
		"if($key.Key -eq 'Escape') { [Console]::WriteLine(); exit 2; };" ^
		"if($key.Key -eq 'Enter') { [Console]::WriteLine(); break; };" ^
		"if($key.Key -eq 'Backspace') { if($buffer.Length -gt 0) { [void]$buffer.Remove($buffer.Length - 1, 1); [Console]::Write(([char]8).ToString() + ' ' + ([char]8).ToString()); }; continue; };" ^
		"if(-not [char]::IsControl($key.KeyChar)) { [void]$buffer.Append($key.KeyChar); [Console]::Write($key.KeyChar); };" ^
	"}; [IO.File]::WriteAllText($env:manualInputFile, $buffer.ToString(), [Console]::OutputEncoding);"
set "manualInputExitCode=!errorlevel!"
if "!manualInputExitCode!"=="2" (
	call :finish_input
	exit /b 2
)
if "!manualInputExitCode!"=="3" goto read_input_line
if not "!manualInputExitCode!"=="0" (
	if exist "!manualInputFile!" del /q "!manualInputFile!" >nul 2>nul
	exit /b 1
)
set /p "input=" < "!manualInputFile!"
del /q "!manualInputFile!" >nul 2>nul
goto normalize_input

REM No CALL expansion of input values; preserve %, ! and shell metacharacters.
:read_input
set "input="
call :write_input_prompt

:read_input_line
set /p "input="

:normalize_input
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
