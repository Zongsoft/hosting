@echo off

REM 获取ESC字符
for /F "delims=#" %%a in ('"prompt #$E# & echo on & for %%b in (1) do rem"') do set "ESC=%%a"

REM 定义颜色代码
set "RED=%ESC%[91m"
set "GREEN=%ESC%[92m"
set "YELLOW=%ESC%[93m"
set "BLUE=%ESC%[94m"
set "MAGENTA=%ESC%[95m"
set "CYAN=%ESC%[96m"

set "DARK_RED=%ESC%[31m"
set "DARK_GREEN=%ESC%[32m"
set "DARK_YELLOW=%ESC%[33m"
set "DARK_BLUE=%ESC%[34m"
set "DARK_MAGENTA=%ESC%[35m"
set "DARK_CYAN=%ESC%[36m"

set "RESET=%ESC%[0m"

REM 定义容器共用的网络
set "NETWORK=zongsoft-net"

podman network exists %NETWORK%

if %errorlevel% equ 1 (
	podman network create %NETWORK%

	if %errorlevel% equ 0 (
		echo %DARK_GREEN%The podman network "%NETWORK%" created successfully.%RESET%
	) else (
		echo %DARK_RED%ERROR: Failed to create network "%NETWORK%"%RESET%.
		exit /b 1
	)
)

:pod_label
SET pod=
SET /p pod=Please enter the name of the Pod you want to start(%GREEN%host/redis/mysql/postgre/rustfs%RESET%): 

if "%pod%"=="" (
	echo %DARK_RED%Error: %RED%The pod name cannot be empty.%RESET%
	echo %DARK_YELLOW%Note: %CYAN%To exit, please enter exit.%RESET%

	goto pod_label
)

if /i "%pod%"=="host" (
	podman kube play --network %NETWORK% --replace .\zongsoft.pod-host.yaml
) else if /i "%pod%"=="redis" (
	podman kube play --network %NETWORK% --replace .\zongsoft.pod-redis.yaml
) else if /i "%pod%"=="rustfs" (
	podman kube play --network %NETWORK% --replace .\zongsoft.pod-rustfs.yaml
) else if /i "%pod%"=="mysql" (
	podman kube play --network %NETWORK% --replace .\zongsoft.pod-mysql.yaml
) else if /i "%pod%"=="postgre" (
	podman kube play --network %NETWORK% --replace .\zongsoft.pod-postgres.yaml
) else if /i "%pod%"=="postgres" (
	podman kube play --network %NETWORK% --replace .\zongsoft.pod-postgres.yaml
) else if /i "%pod%"=="postgresql" (
	podman kube play --network %NETWORK% --replace .\zongsoft.pod-postgres.yaml
) else (
	if /i "%pod%" neq "exit" (
		echo %DARK_MAGENTA%Invalid pod name, please re-enter it.%RESET%
		echo %DARK_YELLOW%Note: %CYAN%To exit, please enter exit.%RESET%

		goto pod_label
	)
)
