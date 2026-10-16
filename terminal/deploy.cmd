@echo off
setlocal EnableExtensions DisableDelayedExpansion

pushd "%~dp0" || exit /b 1

call "..\deploy.cmd" "." --local
set "result=%errorlevel%"

popd
endlocal & exit /b %result%
