@echo off
setlocal

pushd "%~dp0" || exit /b 1

set "COMPOSE_FILE=%~dp0zongsoft.compose.yaml"
set "PROJECT_NAME=zongsoft"
set "NETWORK_NAME=zongsoft-net"
set "SERVICE=%~1"

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

podman network exists "%NETWORK_NAME%"
if errorlevel 1 (
	podman network create "%NETWORK_NAME%"
	if errorlevel 1 (
		echo ERROR: Failed to create network "%NETWORK_NAME%".
		goto failure
	)
)

:service_prompt
if not defined SERVICE set /p "SERVICE=Please enter the service to start (host/etcd/redis/mysql/postgres/rustfs/*/exit): "

if not defined SERVICE (
	echo ERROR: The service name cannot be empty.
	goto service_prompt
)

if /i "%SERVICE%"=="exit" goto success
if /i "%SERVICE%"=="postgre" set "SERVICE=postgres"
if /i "%SERVICE%"=="postgresql" set "SERVICE=postgres"
if "%SERVICE%"=="*" goto start_all

for %%S in (host etcd redis mysql postgres rustfs) do if /i "%SERVICE%"=="%%S" goto start_service

echo ERROR: Invalid service name "%SERVICE%".
set "SERVICE="
goto service_prompt

:start_service
podman compose --file "%COMPOSE_FILE%" --project-name "%PROJECT_NAME%" up --detach "%SERVICE%"
if errorlevel 1 goto failure
goto show_status

:start_all
podman compose --file "%COMPOSE_FILE%" --project-name "%PROJECT_NAME%" up --detach
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
