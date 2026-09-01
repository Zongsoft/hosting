@echo off
setlocal

pushd "%~dp0" || exit /b 1

set "COMPOSE_FILE=%~dp0zongsoft.compose.yaml"
set "PROJECT_NAME=zongsoft"
set "SERVICE=%~1"
set "MODE=%~2"
if not defined SERVICE set "INTERACTIVE=1"

where podman >nul 2>nul
if errorlevel 1 (
	echo ERROR: Podman was not found in PATH.
	goto failure
)

podman info >nul 2>nul
if errorlevel 1 (
	echo ERROR: Podman is unavailable. Make sure the Podman machine is running.
	goto failure
)

podman compose version >nul 2>nul
if errorlevel 1 (
	echo ERROR: No Docker Compose provider is available to Podman.
	goto failure
)

:service_prompt
if not defined SERVICE set /p "SERVICE=Please enter the service to stop (host/etcd/redis/mysql/postgres/rustfs/*/exit): "

if not defined SERVICE (
	echo ERROR: The service name cannot be empty.
	goto service_prompt
)

if /i "%SERVICE%"=="exit" goto success
if /i "%SERVICE%"=="postgre" set "SERVICE=postgres"
if /i "%SERVICE%"=="postgresql" set "SERVICE=postgres"
if "%SERVICE%"=="*" goto validate_mode

for %%S in (host etcd redis mysql postgres rustfs) do if /i "%SERVICE%"=="%%S" goto validate_mode

echo ERROR: Invalid service name "%SERVICE%".
set "SERVICE="
goto service_prompt

:validate_mode
if defined INTERACTIVE if not defined MODE set /p "MODE=Remove the container and discard its writable data? (y/N): "

set "CLEAN="
if /i "%MODE%"=="y" set "CLEAN=1"
if /i "%MODE%"=="yes" set "CLEAN=1"
if /i "%MODE%"=="clean" set "CLEAN=1"
if /i "%MODE%"=="--clean" set "CLEAN=1"
if /i "%MODE%"=="/clean" set "CLEAN=1"
if /i "%MODE%"=="--remove" set "CLEAN=1"

if not defined MODE goto stop_service
if /i "%MODE%"=="n" goto stop_service
if /i "%MODE%"=="no" goto stop_service
if /i "%MODE%"=="keep" goto stop_service
if /i "%MODE%"=="--keep" goto stop_service
if defined CLEAN goto clean_service

echo ERROR: Invalid stop mode "%MODE%". Use --keep or --clean.
goto failure

:stop_service
if "%SERVICE%"=="*" goto stop_all
podman compose --file "%COMPOSE_FILE%" --project-name "%PROJECT_NAME%" stop --timeout 30 "%SERVICE%"
if errorlevel 1 goto failure
goto show_status

:stop_all
podman compose --file "%COMPOSE_FILE%" --project-name "%PROJECT_NAME%" stop --timeout 30
if errorlevel 1 goto failure
goto show_status

:clean_service
if "%SERVICE%"=="*" goto clean_all
podman compose --file "%COMPOSE_FILE%" --project-name "%PROJECT_NAME%" rm --stop --force --volumes "%SERVICE%"
if errorlevel 1 goto failure
goto show_status

:clean_all
podman compose --file "%COMPOSE_FILE%" --project-name "%PROJECT_NAME%" down --remove-orphans --volumes
if errorlevel 1 goto failure

:show_status
podman compose --file "%COMPOSE_FILE%" --project-name "%PROJECT_NAME%" ps --all
goto success

:failure
popd
exit /b 1

:success
popd
exit /b 0
