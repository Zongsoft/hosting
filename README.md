[简体中文](./README.zh-Hans.md)

## Hosts

Applications are currently divided into three host types:

- Terminal applications
	> Run in a console and are suitable for debugging.

- Daemon applications
	> Compilation and deployment must target a specific operating-system platform, and the application runs under a platform-specific service manager.
	> - On Linux/Unix, the application is managed by systemd and requires the corresponding `*.service` file;
	> - On Windows, the application is managed by the Service Control Manager and installation must run with administrator privileges;
	> 	- Use [install.cmd](./daemon/install.cmd) to install the service;
	> 	- Use [uninstall.cmd](./daemon/uninstall.cmd) to uninstall the service.

- Web applications
	> Web backend applications are usually organized by site. Common sites include:
	> - administration
	> - business
	> - customer
	> - partner
	> - gateway
	> - IoT

## Deployment

A host application is responsible only for initializing the runtime environment. It serves as a plugin container and contains no concrete business implementation itself. Deployment means placing the required plugins and their related files, such as configuration and certificates, in the appropriate subdirectories under `plugins`.

Run `deploy.cmd` on Windows or `deploy.sh` on Linux/Unix to perform the operations defined by the deployment files (`*.deploy`).

> The deployment scripts use **Z**ongsoft.**T**ools.**D**eployer. For usage instructions, see the documentation in its open-source repository:
> - English: [https://github.com/Zongsoft/tools/blob/main/deployer/README.md](https://github.com/Zongsoft/tools/blob/main/deployer/README.md)
> - Chinese: [https://github.com/Zongsoft/tools/blob/main/deployer/README-zh_CN.md](https://github.com/Zongsoft/tools/blob/main/deployer/README-zh_CN.md)

### Deployment Files

Configuration files are usually specific to a product, project, deployment platform (such as standalone, intranet, private cloud, or public cloud), and environment (such as development, testing, or production). Store these context-specific files separately under `/hosting/.deploy` for centralized management and maintenance.

> For more deployment-item examples, see the `.deploy` files in the host application directories.

#### Configuration Files

Configuration files should be named according to the environment to which their contents apply, with the environment name appended to the base file name. The following examples use configuration files from the **Zongsoft.Security** plugin:

- `Zongsoft.Security.option`
	> Environment-independent configuration whose values act as defaults for environment-specific files.
-----
- `Zongsoft.Security.test.option`
	> Configuration for the **test environment**. For example, its database connection string may point to a **test database** through an **intranet address**.
- `Zongsoft.Security.production.option`
	> Configuration for the **production environment**. For example, its database connection string may point to a **production database** through an **intranet address**.
- `Zongsoft.Security.development.option`
	> Configuration for the **development environment**. For example, its database connection string may point to a **development database** through an **intranet address**.
-----
- `Zongsoft.Security.test-debug.option`
	> Debug configuration for the **test environment**. For example, its database connection string may point to a **test database** through a **public address**.
- `Zongsoft.Security.production-debug.option`
	> Debug configuration for the **production environment**. For example, its database connection string may point to a **production database** through a **public address**.
- `Zongsoft.Security.development-debug.option`
	> Debug configuration for the **development environment**. For example, its database connection string may point to a **development database** through a **public address**.

### Directory Structure

The `.deploy` directory under `hosting` is the root directory for deployment-related resources. Its structure is as follows:

- `certificates`: certificate files
	> Certificates that are independent of a deployment platform.

- `{scheme}`: deployment scheme
	- `certificates`: certificate files
		> Certificates associated with the deployment scheme.
	- `options`: configuration files

### Deployment Tool

Before running `deploy.cmd`, make sure the deployer tool is installed. Use the following command to list installed global tools:

```bash
dotnet tool list -g
```

If the deployer is not installed, install it globally:

```bash
dotnet tool install -g zongsoft.tools.deployer
```

If it is already installed, update it with:

```bash
dotnet tool update -g zongsoft.tools.deployer
```

> 💡 For more information about the design and implementation of **Z**ongsoft.**T**ools.**D**eployer, visit its open-source repository: [https://github.com/Zongsoft/tools/deployer](https://github.com/Zongsoft/tools/tree/main/deployer)

-----

> 💡 To build and debug the [**Z**ongsoft framework source](https://github.com/Zongsoft/framework) locally, install [**C**ake.**T**ool](https://cakebuild.net/docs/getting-started/setting-up-a-new-scripting-project):
> ```bash
> dotnet tool install -g cake.tool
> ```

## Containerization

Some plugins depend on Redis, RustFS, MySQL, PostgreSQL, or Etcd. This project therefore supports two equivalent _**P**odman_-based/_**D**ocker_-based local containerization modes. Both modes cover the same development host and infrastructure services, and users may choose either one based on their preferred tools and data-lifecycle requirements.

### Runtime Modes

Mode | Definition files | Management commands | Data lifecycle | Typical use
-----|------------------|---------------------|----------------|------------
K8s Pod | `zongsoft.pod-*.yaml` | `podman kube play/down` | Removing a Pod discards container data | Describe services with Kubernetes manifests and manage them as Pods
Podman + Docker Compose | `zongsoft.compose.yaml` | `podman compose` | Container data can be preserved or cleared | Describe services with the Compose model and manage individual services or the project

Both modes can be installed on the same machine, but do not use both modes to start the same service at the same time. They share Windows host ports, the `zongsoft-net` network, and some network aliases.

### Common Environment Setup

Install the Podman CLI from one of the following locations:

- https://podman.io
- https://github.com/containers/podman/releases

> 💡 On Windows, make sure [WSL 2](https://learn.microsoft.com/windows/wsl/install) is installed.

#### Docker Compose Provider (Compose Mode Only)

Skip this section when using K8s Pod mode. For Compose mode, install a Docker Compose Provider as follows:

1. Download [Docker Compose for Windows x64](https://github.com/docker/compose/releases/download/v5.5.0/docker-compose-windows-x86_64.exe) from the [Docker Compose releases](https://github.com/docker/compose/releases/download) page;
2. Rename the downloaded file to `docker-compose.exe` and copy it to the Podman installation directory, for example `C:\Program Files\RedHat\Podman`;
3. Create an environment variable named `PODMAN_COMPOSE_PROVIDER` whose value is the full path to `docker-compose.exe`, for example `C:\Program Files\RedHat\Podman\docker-compose.exe`;
4. Verify the installation by running `podman compose version` in a terminal.

#### Network Mode

The `%USERPROFILE%` directory may contain a `.wslconfig` file that specifies the WSL network mode, for example:

```ini
[wsl2]
networkingMode=Mirrored
dnsTunneling=true
firewall=false
autoProxy=true
```

💡 **Note:** This configuration enables mirrored networking. In this mode, multiple container instances may be unable to communicate with one another, even when `.wslconfig` contains `hostAddressLoopback=true` and the container YAML specifies `hostNetwork: true`. NAT mode is a more reliable option for this setup. Use the following steps to reset WSL networking to NAT mode.

1. Shut down WSL:

```shell
wsl --shutdown
```

2. Delete `.wslconfig`:

	- Option 1: Enter `%USERPROFILE%` in the File Explorer address bar, enable display of hidden files if necessary, and delete `.wslconfig`.

	- Option 2: Run the following command in PowerShell on the Windows host:
		> ```shell
		> rm $env:USERPROFILE\.wslconfig -Force
		> ```

3. Reset the network settings.

> Run the following commands in PowerShell on the Windows host.<br />
> You may need to restart Windows afterward.

```shell
netsh winsock reset
netsh int ip reset
```

4. Check the network after restarting:

```shell
# Check the WSL network interface state
wsl ip addr show eth0

# Check whether a port is listening (Redis 6379 in this example)
wsl ss -tlnp | grep ':6379'
```

Expected results:

- The `eth0` interface should be `UP`;
- An `inet` address, usually in a `172.x.x.x` range, should be present.

#### Directory Mapping

For convenient development, host directories can be bind-mounted into the root of the Podman machine:

1. Enter the Podman machine and edit `/etc/fstab`:

	```shell
	sudo vi /etc/fstab
	```

2. Append entries such as:

	```plaintext
	/mnt/d/Automao  /Automao  none bind 0 0
	/mnt/d/Zongsoft /Zongsoft none bind 0 0
	```

3. Restart the Podman machine:

	```shell
	podman machine stop
	podman machine start
	```

#### Registry Mirrors

Depending on local network conditions, configure container registry mirrors before pulling images:

1. Enter the Podman machine:

	```shell
	podman machine ssh
	```

2. Edit the container registry configuration:

	```bash
	sudo vi /etc/containers/registries.conf
	```

	A representative configuration is shown below:

	```toml
	[[registry]]
	  prefix = "docker.io"
	  location = "docker.io"

	[[registry.mirror]]
	  prefix = "mcr.microsoft.com"
	  location = "mcr.m.daocloud.io"

	[[registry.mirror]]
	  location = "docker.m.daocloud.io"
	```

3. Exit and restart the Podman machine:

	```shell
	podman machine stop
	podman machine start
	```

#### Network Proxy

1. Enter the Podman machine:

	```shell
	podman machine ssh
	```

2. Run the following commands inside the Podman machine to create a script that sets proxy environment variables and a systemd service that runs it when the machine starts:

```bash
cat > /usr/local/bin/set-podman-proxy-env.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

WIN_HOST="$(ip route | awk '/default/ {print $3; exit}')"
PROXY="socks5h://${WIN_HOST}:1080"
NO_PROXY_VALUE="localhost,127.0.0.1,::1"

systemctl set-environment \
  HTTP_PROXY="${PROXY}" \
  HTTPS_PROXY="${PROXY}" \
  ALL_PROXY="${PROXY}" \
  http_proxy="${PROXY}" \
  https_proxy="${PROXY}" \
  all_proxy="${PROXY}" \
  NO_PROXY="${NO_PROXY_VALUE}" \
  no_proxy="${NO_PROXY_VALUE}"
EOF

chmod +x /usr/local/bin/set-podman-proxy-env.sh

cat > /etc/systemd/system/podman-proxy-env.service <<'EOF'
[Unit]
Description=Set dynamic Windows proxy environment for Podman machine
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/set-podman-proxy-env.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now podman-proxy-env.service
```

### Database Initialization Prerequisites

Both modes run initialization SQL when a MySQL or PostgreSQL container is first created. Make sure the following repositories are located beside [hosting](https://github.com/Zongsoft/hosting):

- [administratives](https://github.com/Zongsoft/administratives)
- [discussions](https://github.com/Zongsoft/discussions)
- [framework](https://github.com/Zongsoft/framework)

If these repositories or their SQL files are missing, the database containers cannot complete initialization as expected.

### K8s Pod Mode

This mode describes services with Kubernetes Pod YAML and manages the Pods through Podman's `kube play` and `kube down` commands. It requires only the Podman CLI.

#### Pod Files

- [zongsoft.pod-host.yaml](./zongsoft.pod-host.yaml): Development host container with .NET SDK 10, `systemd`, `nginx`, and related tools.
	> This file contains network-proxy settings that should be adjusted for the local environment.
- [zongsoft.pod-etcd.yaml](./zongsoft.pod-etcd.yaml): Etcd distributed-configuration container.
- [zongsoft.pod-redis.yaml](./zongsoft.pod-redis.yaml): Redis distributed-cache container.
- [zongsoft.pod-rustfs.yaml](./zongsoft.pod-rustfs.yaml): RustFS distributed-file-system container.
- [zongsoft.pod-mysql.yaml](./zongsoft.pod-mysql.yaml): MySQL container and initialization scripts.
- [zongsoft.pod-postgres.yaml](./zongsoft.pod-postgres.yaml): PostgreSQL container and initialization scripts.

#### Start a Pod

Double-click `zongsoft.pod(start).cmd` in File Explorer, or run it in Command Prompt:

```cmd
zongsoft.pod(start).cmd
```

Enter the Pod to start when prompted:

- `host`: development host container;
- `etcd`: Etcd;
- `redis`: Redis;
- `rustfs`: RustFS;
- `mysql`: MySQL;
- `postgres`, `postgre`, or `postgresql`: PostgreSQL;
- `exit`: exit the script.

The script ensures that `zongsoft-net` exists, then creates or replaces the selected Pod with `podman kube play --network zongsoft-net --replace`.

Use the following command to inspect Pod and container status:

```shell
podman ps --all --pod
```

#### Stop a Pod

Double-click `zongsoft.pod(stop).cmd` in File Explorer, or run it in Command Prompt:

```cmd
zongsoft.pod(stop).cmd
```

Enter the Pod to stop when prompted. For an individual Pod, the script uses `podman kube down` to stop and remove it.

> ⚠️ Entering `*` runs `podman stop -a` followed by `podman rm -afv`. This affects every container in the current Podman environment, not only this project. Make sure no other containers need to be preserved before using it.

`kube down` removes the Pod and its containers, so data in the containers' writable layers is not preserved. It does not delete the host-mounted RustFS `.attachments` directory or the database initialization SQL source files.

#### Pod Network Addresses

All Pods join `zongsoft-net`. Use the Pod name and container port when one container connects to another Pod:

Pod name | Container name | Address inside the network | Windows address
---------|----------------|----------------------------|----------------
`zongsoft` | `zongsoft-host` | `zongsoft` | _No published port_
`zongsoft.distributed` | `zongsoft.distributed-etcd` | `zongsoft.distributed:2379` | `localhost:2379`
`zongsoft.caching` | `zongsoft.caching-redis` | `zongsoft.caching:6379` | `localhost:6379`
`zongsoft.data` | `zongsoft.data-mysql` | `zongsoft.data:3306` | `localhost:3306`
`zongsoft.data` | `zongsoft.data-postgres` | `zongsoft.data:5432` | `localhost:5432`
`zongsoft.io` | `zongsoft.io-rustfs` | `zongsoft.io:9000` | `localhost:9000`, `localhost:9001`

MySQL and PostgreSQL use the same Pod name, `zongsoft.data`, so choose one database in this mode rather than starting both at the same time.

For example, connect to RustFS and Redis from the development host container:

```shell
podman exec --interactive --tty zongsoft-host bash
curl -L -A "Mozilla/5.0(Linux; x64)" http://zongsoft.io:9001
redis-cli -h zongsoft.caching -p 6379
zongsoft.caching:6379> auth xxxxxx
OK
```

#### Common Pod Commands

```shell
# View logs
podman logs zongsoft-host
podman logs zongsoft.data-mysql
podman logs zongsoft.data-postgres
podman logs zongsoft.caching-redis

# Enter containers
podman exec --interactive --tty zongsoft-host bash
podman exec --interactive --tty zongsoft.data-mysql bash
podman exec --interactive --tty zongsoft.data-postgres bash
podman exec --interactive --tty zongsoft.caching-redis bash

# Start Pods directly without the script
podman network exists zongsoft-net || podman network create zongsoft-net
podman kube play --network zongsoft-net --replace .\zongsoft.pod-redis.yaml
podman kube play --network zongsoft-net --replace .\zongsoft.pod-mysql.yaml
podman kube play --network zongsoft-net --replace .\zongsoft.pod-postgres.yaml

# Stop and remove Pods directly without the script
podman kube down .\zongsoft.pod-host.yaml
podman kube down .\zongsoft.pod-redis.yaml
podman kube down .\zongsoft.pod-mysql.yaml
podman kube down .\zongsoft.pod-postgres.yaml

# The following commands affect every container in the current Podman environment
podman stop -a
podman rm -afv

# Remove the local RustFS image
podman rmi rustfs:latest
```

### Podman + Docker Compose Mode

This mode describes all services in [zongsoft.compose.yaml](./zongsoft.compose.yaml) and invokes a Docker Compose Provider through `podman compose`. It supports per-service startup, selectable data-retention behavior, and project-level management.

#### Compose Services

Service | Purpose
--------|--------
`host` | Development host container with .NET SDK 10, `systemd`, `nginx`, and related tools
`etcd` | Etcd distributed-configuration service
`redis` | Redis distributed-cache service
`mysql` | MySQL database and initialization scripts
`postgres` | PostgreSQL database and initialization scripts
`rustfs` | RustFS distributed-file-system service

Compose generates container names. Use stable service names for routine operations instead of depending on specific container names.

#### Start Compose Services

Double-click `zongsoft.compose(start).cmd` in File Explorer, or pass a service name directly:

```cmd
zongsoft.compose(start).cmd redis
zongsoft.compose(start).cmd mysql
zongsoft.compose(start).cmd "*"
```

The script accepts `host`, `etcd`, `redis`, `mysql`, `postgres`, `rustfs`, and `*`. An asterisk starts every service defined in `zongsoft.compose.yaml`.

The startup script checks Podman, the Docker Compose Provider, and the Podman machine, then idempotently creates the external shared network `zongsoft-net`.

Use the following command to inspect services in this project:

```shell
podman compose --file zongsoft.compose.yaml --project-name zongsoft ps --all
```

#### Stop Compose Services

The stop script supports both data-preserving and data-clearing modes:

```cmd
# Default: stop containers and preserve writable layers and anonymous volumes
zongsoft.compose(stop).cmd mysql
zongsoft.compose(stop).cmd mysql --keep

# Stop and remove the container and anonymous volumes, clearing container data
zongsoft.compose(stop).cmd mysql --clean

# Clear all Compose containers and anonymous volumes in this project
zongsoft.compose(stop).cmd "*" --clean
```

When launched interactively, the script asks whether to remove the container and clear its data.

- `--keep` uses `podman compose stop`, allowing a subsequent start to reuse the same container data;
- `--clean` uses `podman compose rm --stop --force --volumes` for an individual service;
- `* --clean` uses `podman compose down --remove-orphans --volumes`;
- Neither behavior deletes the external shared network `zongsoft-net`;
- `--clean` does not delete the host-mounted RustFS `.attachments` directory or the database initialization SQL source files.

#### Compose Network Addresses

All Compose services join `zongsoft-net` and can reach one another by service name or network alias:

Service | Address inside the network | Windows address
--------|----------------------------|----------------
`host` | `host` or `zongsoft` | _No published port_
`etcd` | `etcd:2379` or `zongsoft.distributed:2379` | `localhost:2379`
`redis` | `redis:6379` or `zongsoft.caching:6379` | `localhost:6379`
`mysql` | `mysql:3306` or `zongsoft.data.mysql:3306` | `localhost:3306`
`postgres` | `postgres:5432` or `zongsoft.data.postgres:5432` | `localhost:5432`
`rustfs` | `rustfs:9000` or `zongsoft.io:9000` | `localhost:9000`, `localhost:9001`

MySQL and PostgreSQL use different service names and network aliases in this mode and can run at the same time.

Containers access the Windows host through `host.containers.internal`. For example, if a Windows service listens on port `8080`, use the following address inside a container:

```text
http://host.containers.internal:8080
```

The `host` service uses `http://host.containers.internal:1080` as its default network proxy. Override it with the `ZONGSOFT_HTTP_PROXY` and `ZONGSOFT_HTTPS_PROXY` environment variables.

#### Common Compose Commands

```shell
# View logs
podman compose --file zongsoft.compose.yaml --project-name zongsoft logs host
podman compose --file zongsoft.compose.yaml --project-name zongsoft logs mysql
podman compose --file zongsoft.compose.yaml --project-name zongsoft logs postgres
podman compose --file zongsoft.compose.yaml --project-name zongsoft logs redis

# Enter containers
podman compose --file zongsoft.compose.yaml --project-name zongsoft exec host bash
podman compose --file zongsoft.compose.yaml --project-name zongsoft exec mysql bash
podman compose --file zongsoft.compose.yaml --project-name zongsoft exec postgres bash
podman compose --file zongsoft.compose.yaml --project-name zongsoft exec redis bash

# Start individual services directly
podman network exists zongsoft-net || podman network create zongsoft-net
podman compose --file zongsoft.compose.yaml --project-name zongsoft up --detach redis
podman compose --file zongsoft.compose.yaml --project-name zongsoft up --detach mysql
podman compose --file zongsoft.compose.yaml --project-name zongsoft up --detach postgres

# Stop services and preserve data
podman compose --file zongsoft.compose.yaml --project-name zongsoft stop redis mysql postgres

# Remove project containers while preserving anonymous volumes and the shared network
podman compose --file zongsoft.compose.yaml --project-name zongsoft down

# Remove project containers and anonymous volumes while preserving the shared network
podman compose --file zongsoft.compose.yaml --project-name zongsoft down --volumes
```

### Notes Common to Both Modes

#### Switching Between Modes

Both modes share `zongsoft-net`, Windows host ports, and some network aliases. Do not start the same service in both modes at the same time, or port and network-name conflicts will occur.

Before switching modes, stop the relevant services with the script for the currently active mode:

- K8s Pod to Compose: run `zongsoft.pod(stop).cmd` and stop the relevant Pod;
- Compose to K8s Pod: run `zongsoft.compose(stop).cmd <service> --clean` and remove the relevant Compose container.

#### Communication Between Windows and Containers

- Windows accesses infrastructure services through `localhost` and the corresponding published port;
- Containers access Windows through `host.containers.internal`;
- Containers access one another through the Pod names, service names, or network aliases documented for the selected mode;
- Do not hard-code container IP addresses because they can change when containers are recreated.

#### Startup Readiness

- On its first start, the `host` container installs and initializes tools such as `systemd` and `nginx`, so it may need additional time after the container reports that it is running;
- On their first start, MySQL and PostgreSQL execute schema and data initialization SQL. Wait for initialization to complete before connecting;
- Use the log commands for the selected mode to monitor initialization progress.

#### Default Development Credentials

Service | User name or access key | Password or secret key
--------|-------------------------|-----------------------
Redis | _No user name_ | `xxxxxx`
MySQL | `program` | `xxxxxx`
PostgreSQL | `program` | `xxxxxx`
RustFS | `rustfsadmin` | `rustfsadmin`

These credentials are intended only for local development. In Compose mode, override the defaults with the `ZONGSOFT_REDIS_PASSWORD`, `ZONGSOFT_MYSQL_PASSWORD`, `ZONGSOFT_POSTGRES_PASSWORD`, `ZONGSOFT_RUSTFS_ACCESS_KEY`, and `ZONGSOFT_RUSTFS_SECRET_KEY` environment variables.
