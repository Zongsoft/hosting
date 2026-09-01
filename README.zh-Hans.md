[English](./README.md)

## 宿主

目前应用程序按宿主类型分为以下三种：

- 终端应用 _(**T**erminal)_
	> 通过控制台运行，适用调试。

- 后台应用 _(**D**aemon)_
	> 编译和部署需要指定操作系统平台，由特定的容器进行托管运行。
	> - _**L**inux/**U**nix_ 系统中由 _systemd_ 进行托管，需要部署对应的 `*.service` 文件；
	> - _**W**indows_ 系统中由服务控制器进行托管，需要以 _管理员_ 模式运行；
	> 	- 使用 [_install.cmd_](./daemon/install.cmd) 脚本安装服务；
	> 	- 使用 [_uninstall.cmd_](./daemon/uninstall.cmd) 脚本卸载服务；

- 网站应用 _(**W**eb)_
	> 表示 _**W**eb_ 后台应用程序，通常按站点进行划分，常用站点：
	> - 管理端 _(administration)_
	> - 商家端 _(business)_
	> - 客户端 _(customer)_
	> - 伙伴端 _(partner)_
	> - 网关端 _(gateway)_
	> - 设备端 _(iot)_

## 部署

宿主程序只负责初始化运行时环境，作为插件的承载容器其自身并不含有具体的功能实现，我们通过将需要的插件及其相关附属(配置、证书)文件放置在 `plugins` 目录下的相应子目录中，这个行为即为部署。

运行 `deploy.cmd` _(**W**indows)_ 或 `deploy.sh` _(**L**inux/**U**nix)_ 脚本以执行由部署文件 _(`*.deploy`)_ 所定义的部署内容。

> 提示：部署脚本依赖 **Z**ongsoft.**T**ools.**D**eployer 工具进行部署操作，有关该工具的使用说明，请参考其开源项目的相关文档：
> - 英文：[https://github.com/Zongsoft/tools/blob/main/deployer/README.md](https://github.com/Zongsoft/tools/blob/main/deployer/README.md)
> - 中文：[https://github.com/Zongsoft/tools/blob/main/deployer/README-zh_CN.md](https://github.com/Zongsoft/tools/blob/main/deployer/README-zh_CN.md)

### 部署文件

通常配置文件与特定的 **产品**、**项目**、**部署平台** _（如：单机、内网、私有云、公有云）_ 及 **环境** _（如：开发、测试、生产）_ 等相关，所以应该将这些特定相关性的文件单独存放在 `/hosting/.deploy` 目录下，以便于统一管理与维护。

> 提示：更多部署项的用法请参考宿主程序目录中的 `.deploy` 部署文件。

#### 配置文件

应该根据配置内容的环境相关性来定义配置文件，相应的环境名作为配置文件名的尾部。下面以 **Zongsoft.Security** 插件的配置文件为例进行说明：

- `Zongsoft.Security.option`
	> 表示环境无关的配置文件，其配置作为其他环境有关性配置的缺省值；
-----
- `Zongsoft.Security.test.option`
	> 表示**测试环境**有关的配置文件，譬如该配置文件内的数据库连接字符串指向的是**测试数据库**并且使用的是**内网地址**等。
- `Zongsoft.Security.production.option`
	> 表示**生产环境**有关的配置文件，譬如该配置文件内的数据库连接字符串指向的是**生产数据库**并且使用的是**内网地址**等。
- `Zongsoft.Security.development.option`
	> 表示**开发环境**有关的配置文件，譬如该配置文件内的数据库连接字符串指向的是**开发数据库**并且使用的是**内网地址**等。
-----
- `Zongsoft.Security.test-debug.option`
	> 表示**测试环境**有关的配置文件，譬如该配置文件内的数据库连接字符串指向的是**测试数据库**并且使用的是**外网地址**等。
- `Zongsoft.Security.production-debug.option`
	> 表示**生产环境**有关的配置文件，譬如该配置文件内的数据库连接字符串指向的是**生产数据库**并且使用的是**外网地址**等。
- `Zongsoft.Security.development-debug.option`
	> 表示**开发环境**有关的配置文件，譬如该配置文件内的数据库连接字符串指向的是**开发数据库**并且使用的是**外网地址**等。

### 目录结构

位于 `hosting` 目录下的 `.deploy` 目录即为存放部署相关的各种资源的‘根’目录，其下级结构如下：

- `certificates` 证书文件目录
	> 注：部署平台无关的证书文件。

- `{scheme}` 部署方案
	- `certificates` 证书文件目录
		> 注：与部署方案有关联的证书文件。
	- `options` 配置文件目录

### 部署工具

在运行 `deploy.cmd` 脚本之前必须确保 `deploy` 工具已经安装，可通过下面命令查看已安装的全局工具：
```bash
dotnet tool list -g
```

如果尚未安装 `deploy` 工具，可通过下面命令进行全局安装：
```bash
dotnet tool install -g zongsoft.tools.deployer
```

如果已经安装了 `deploy` 工具，可通过下面命令进行升级更新：
```bash
dotnet tool update -g zongsoft.tools.deployer
```

> 💡 有关 **Z**ongsoft.**T**ools.**D**eployer 部署工具的更多内部原理与实现，请访问该项目的开源网址：[https://github.com/Zongsoft/tools/deployer](https://github.com/Zongsoft/tools/tree/main/deployer)

-----

> 💡 如果需要本地编译调试 _**Z**ongsoft_ 框架[源码](https://github.com/Zongsoft/framework)，建议安装 [_**C**ake.**T**ool_](https://cakebuild.net/docs/getting-started/setting-up-a-new-scripting-project) 工具：
> ```bash
> dotnet tool install -g cake.tool
> ```

## 容器化

由于一些插件依赖 Redis、RustFS、MySQL、PostgreSQL 或 Etcd，因此本项目同时支持两种基于 _**P**odman/**D**ocker_ 的本地容器化模式。两种模式地位相同，覆盖相同的开发宿主和基础服务，用户可以根据工具习惯与数据生命周期需求自由选择。

### 运行模式

模式 | 定义文件 | 管理命令 | 数据生命周期 | 适用场景
-----|----------|----------|--------------|---------
K8s Pod | `zongsoft.pod-*.yaml` | `podman kube play/down` | 停止 Pod 时删除容器数据 | 使用 Kubernetes 清单描述服务，按 Pod 创建和销毁
Podman + Docker Compose | `zongsoft.compose.yaml` | `podman compose` | 可选择保留或清除容器数据 | 使用 Compose 服务模型，按服务或项目管理

两种模式可以安装在同一台机器上，但不要同时用两种模式启动同一个服务，因为它们共享 Windows 宿主端口、`zongsoft-net` 网络以及部分网络别名。

### 共同环境准备

> 建议安装 _**P**odman_ _**CLI**_ 进行容器化处理，下面是它的下载地址：
> - https://podman.io
> - https://github.com/containers/podman/releases

> 💡 如果是 _**W**indows_ 环境，请确保安装了 [_WSL-2_](https://learn.microsoft.com/zh-cn/windows/wsl/install)。

#### Docker Compose Provider（仅 Compose 模式）

选择 K8s Pod 模式时可以跳过本节。选择 Compose 模式时，按下列步骤安装 Docker Compose Provider：

1. 从 https://github.com/docker/compose/releases/download 下载 [**D**ocker-**C**ompose _(Win-X64)_](https://github.com/docker/compose/releases/download/v5.5.0/docker-compose-windows-x86_64.exe) 插件；
2. 将下载的文件更名为 `docker-compose.exe`，并拷贝到 _**P**odman_ 目录中 _（譬如：`C:\Program Files\RedHat\Podman`）_；
3. 创建一个名为 `PODMAN_COMPOSE_PROVIDER` 的环境变量，其值为 `docker-compose.exe` 文件的完整路径 _（譬如：`C:\Program Files\RedHat\Podman\docker-compose.exe`）_；
4. 在终端运行 `podman compose version` 命令进行验证。

#### 网络模式

在 `%USERPROFILE%` 目录中可能存在名为 `.wslconfig` 文件，该文件中可能指定了 _WSL_ 的网络模式，譬如：

```ini
[wsl2]
networkingMode=Mirrored
dnsTunneling=true
firewall=false
autoProxy=true
```

💡 **注意**：这表明 _WSL_ 网络模式为 _镜像_ 模式，这种模式下的多个容器实例之间网络很可能无法互通，即使在 `.wslconfig` 文件中指定了 `hostAddressLoopback=true` 选项，同时在 `.yaml` 容器文件中也指定了 `hostNetwork: true` 参数都不行，更稳妥的方案是采用 `NAT` 网络模式。下面是重置 _WSL_ 网络模式为 `NAT` 模式的操作步骤。

1. 关闭 _WSL_ 虚拟机

```shell
wsl --shutdown
```

2. 删除 `.wslconfig` 文件

	- 方式一：在文件资源管理器地址栏输入：`%USERPROFILE%`，找到并删除 `.wslconfig` 文件。
		> 需要在资源管理器的选项设置中开启显示隐藏文件。

	- 方式二：在宿主机的 _**P**ower**S**hell_ 中执行下列命令进行删除：
		> ```shell
		> rm $env:USERPROFILE\.wslconfig -Force
		> ```

3. 重置网络设置

> 在宿主机的 _**P**ower**S**hell_ 中执行以下命令：<br />
> 注：执行完下面两步后可能需要重启电脑。

```shell
netsh winsock reset
netsh int ip reset
```

4. 检查网络情况

> 重启后，在宿主机的 _**P**ower**S**hell_ 中执行以下命令：

```shell
# 检查 WSL 网络接口状态
wsl ip addr show eth0

# 检查某个端口是否可访问(以6379为例)
wsl ss -tlnp | grep ':6379'
```

> 预期结果：
> - 返回的 `eth0` 网络接口状态应该变为 `UP`
> - 应该能看到 `inet` 地址 _(通常为 `172.x.x.x` 范围)_

#### 目录映射

为方便开发，可以将宿主机中的相关开发目录映射到虚拟机的根目录中，操作步骤：

- 进入虚拟机，编辑 `/etc/fstab` 文件：

	```shell
	sudo vi /etc/fstab
	```

- 在文件末尾追加 _(示例)_：

	```plaintext
	/mnt/d/Automao  /Automao  none bind 0 0
	/mnt/d/Zongsoft /Zongsoft none bind 0 0
	```

- 重启虚拟机

	```shell
	podman machine stop
	podman machine start
	```

#### 镜像配置

基于某些众所周知的国情，务必先配置 _**D**ocker_ 镜像，步骤如下：

1. 进入虚拟机

	```shell
	podman machine ssh
	```

2. 编辑容器注册表文件

	```bash
	sudo vi /etc/containers/registries.conf
	```

	> 编辑该文件内容大致如下：

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

3. 退出并重启虚拟机
	```shell
	podman machine stop
	podman machine start
	```

#### 网络代理

1. 进入虚拟机

	```shell
	podman machine ssh
	```

2. 在容器虚拟机内运行下面命令：

	> - 创建一个设置网络代理环境变量的脚本文件；
	> - 创建一个 systemd 后台服务，使其在容器启动时运行上面的脚本；

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


### 数据库初始化前置条件

两种模式都会在首次创建 MySQL 或 PostgreSQL 容器时运行初始化 SQL。请确保 [hosting](https://github.com/Zongsoft/hosting) 的同级目录中存在下列仓库：

- [administratives](https://github.com/Zongsoft/administratives)
- [discussions](https://github.com/Zongsoft/discussions)
- [framework](https://github.com/Zongsoft/framework)

如果这些仓库或 SQL 文件缺失，数据库容器将无法按预期完成初始化。

### K8s Pod 模式

该模式使用 Kubernetes Pod YAML 描述服务，通过 Podman 的 `kube play` 和 `kube down` 命令管理 Pod，只需要 Podman CLI。

#### Pod 文件

- [zongsoft.pod-host.yaml](./zongsoft.pod-host.yaml)：包含 .NET SDK 10、`systemd` 和 `nginx` 等工具的开发宿主容器。
	> 该文件包含网络代理配置，应根据本机环境调整。
- [zongsoft.pod-etcd.yaml](./zongsoft.pod-etcd.yaml)：Etcd 分布式配置容器。
- [zongsoft.pod-redis.yaml](./zongsoft.pod-redis.yaml)：Redis 分布式缓存容器。
- [zongsoft.pod-rustfs.yaml](./zongsoft.pod-rustfs.yaml)：RustFS 分布式文件系统容器。
- [zongsoft.pod-mysql.yaml](./zongsoft.pod-mysql.yaml)：MySQL 数据库容器及初始化脚本。
- [zongsoft.pod-postgres.yaml](./zongsoft.pod-postgres.yaml)：PostgreSQL 数据库容器及初始化脚本。

#### 启动 Pod

在文件资源管理器中双击 `zongsoft.pod(start).cmd`，或者在命令提示符中运行：

```cmd
zongsoft.pod(start).cmd
```

根据提示输入需要启动的 Pod：

- `host`：开发宿主容器；
- `etcd`：Etcd；
- `redis`：Redis；
- `rustfs`：RustFS；
- `mysql`：MySQL；
- `postgres`、`postgre` 或 `postgresql`：PostgreSQL；
- `exit`：退出脚本。

脚本会确保 `zongsoft-net` 网络存在，再通过 `podman kube play --network zongsoft-net --replace` 创建或替换指定 Pod。

使用下列命令查看 Pod 和容器状态：

```shell
podman ps --all --pod
```

#### 停止 Pod

在文件资源管理器中双击 `zongsoft.pod(stop).cmd`，或者在命令提示符中运行：

```cmd
zongsoft.pod(stop).cmd
```

根据提示输入要停止的 Pod。输入单个名称时，脚本通过 `podman kube down` 停止并删除该 Pod。

> ⚠️ 输入 `*` 会执行 `podman stop -a` 和 `podman rm -afv`，影响当前 Podman 环境中的所有容器，而不仅是本项目。使用前应确认没有其他需要保留的容器。

`kube down` 会删除 Pod 和容器，容器可写层中的数据不会保留；RustFS 的 `.attachments` 宿主机绑定目录和数据库初始化 SQL 源文件不会因此删除。

#### Pod 网络地址

所有 Pod 都加入 `zongsoft-net`。容器访问另一个 Pod 时使用 Pod 名和容器端口：

Pod 名 | 容器名 | Pod 内地址 | Windows 地址
-------|--------|------------|-------------
`zongsoft` | `zongsoft-host` | `zongsoft` | _未映射端口_
`zongsoft.distributed` | `zongsoft.distributed-etcd` | `zongsoft.distributed:2379` | `localhost:2379`
`zongsoft.caching` | `zongsoft.caching-redis` | `zongsoft.caching:6379` | `localhost:6379`
`zongsoft.data` | `zongsoft.data-mysql` | `zongsoft.data:3306` | `localhost:3306`
`zongsoft.data` | `zongsoft.data-postgres` | `zongsoft.data:5432` | `localhost:5432`
`zongsoft.io` | `zongsoft.io-rustfs` | `zongsoft.io:9000` | `localhost:9000`、`localhost:9001`

MySQL 与 PostgreSQL 使用相同的 Pod 名 `zongsoft.data`，因此该模式下应根据需要选择其中一种数据库，不要同时启动两者。

例如，从开发宿主容器访问 RustFS 和 Redis：

```shell
podman exec --interactive --tty zongsoft-host bash
curl -L -A "Mozilla/5.0(Linux; x64)" http://zongsoft.io:9001
redis-cli -h zongsoft.caching -p 6379
zongsoft.caching:6379> auth xxxxxx
OK
```

#### Pod 常用命令

```shell
# 查看日志
podman logs zongsoft-host
podman logs zongsoft.data-mysql
podman logs zongsoft.data-postgres
podman logs zongsoft.caching-redis

# 进入容器
podman exec --interactive --tty zongsoft-host bash
podman exec --interactive --tty zongsoft.data-mysql bash
podman exec --interactive --tty zongsoft.data-postgres bash
podman exec --interactive --tty zongsoft.caching-redis bash

# 不使用脚本，直接启动 Pod
podman network exists zongsoft-net || podman network create zongsoft-net
podman kube play --network zongsoft-net --replace .\zongsoft.pod-redis.yaml
podman kube play --network zongsoft-net --replace .\zongsoft.pod-mysql.yaml
podman kube play --network zongsoft-net --replace .\zongsoft.pod-postgres.yaml

# 不使用脚本，直接停止并删除 Pod
podman kube down .\zongsoft.pod-host.yaml
podman kube down .\zongsoft.pod-redis.yaml
podman kube down .\zongsoft.pod-mysql.yaml
podman kube down .\zongsoft.pod-postgres.yaml

# 下列命令影响当前 Podman 环境的全部容器，使用前务必确认范围
podman stop -a
podman rm -afv

# 删除本地 RustFS 镜像
podman rmi rustfs:latest
```

### Podman + Docker Compose 模式

该模式使用 [zongsoft.compose.yaml](./zongsoft.compose.yaml) 统一描述服务，通过 `podman compose` 调用 Docker Compose Provider，支持按服务启停、选择数据保留策略和进行项目级管理。

#### Compose 服务

服务名 | 用途
-------|-----
`host` | 包含 .NET SDK 10、`systemd` 和 `nginx` 等工具的开发宿主容器
`etcd` | Etcd 分布式配置服务
`redis` | Redis 分布式缓存服务
`mysql` | MySQL 数据库及初始化脚本
`postgres` | PostgreSQL 数据库及初始化脚本
`rustfs` | RustFS 分布式文件系统

Compose 容器名称由 Compose 生成，日常操作应使用稳定的服务名，不要依赖具体容器名。

#### 启动 Compose 服务

在文件资源管理器中双击 `zongsoft.compose(start).cmd`，或者直接传入服务名：

```cmd
zongsoft.compose(start).cmd redis
zongsoft.compose(start).cmd mysql
zongsoft.compose(start).cmd "*"
```

支持 `host`、`etcd`、`redis`、`mysql`、`postgres`、`rustfs` 和 `*`；其中 `*` 表示启动 `zongsoft.compose.yaml` 中的全部服务。

启动脚本会依次检查 Podman、Docker Compose Provider 和 Podman machine，并幂等创建外部共享网络 `zongsoft-net`。

使用下列命令查看本项目服务状态：

```shell
podman compose --file zongsoft.compose.yaml --project-name zongsoft ps --all
```

#### 停止 Compose 服务

停止脚本提供保留数据和清除数据两种模式。

```cmd
# 默认行为：停止容器并保留容器可写层和匿名卷
zongsoft.compose(stop).cmd mysql
zongsoft.compose(stop).cmd mysql --keep

# 停止并删除容器及匿名卷，清除容器内数据
zongsoft.compose(stop).cmd mysql --clean

# 清除本项目的全部 Compose 容器及匿名卷
zongsoft.compose(stop).cmd "*" --clean
```

双击脚本交互运行时，脚本会询问是否删除容器并清除数据。

- `--keep` 使用 `podman compose stop`，再次启动时继续使用原容器数据；
- `--clean` 对单个服务使用 `podman compose rm --stop --force --volumes`；
- `* --clean` 使用 `podman compose down --remove-orphans --volumes`；
- 两种模式都不会删除外部共享网络 `zongsoft-net`；
- `--clean` 不会删除 RustFS 的 `.attachments` 绑定目录或数据库初始化 SQL 源文件。

#### Compose 网络地址

所有 Compose 服务都加入 `zongsoft-net`，可以通过服务名或网络别名互相访问：

服务 | 容器内地址 | Windows 地址
-----|------------|-------------
`host` | `host` 或 `zongsoft` | _未映射端口_
`etcd` | `etcd:2379` 或 `zongsoft.distributed:2379` | `localhost:2379`
`redis` | `redis:6379` 或 `zongsoft.caching:6379` | `localhost:6379`
`mysql` | `mysql:3306` 或 `zongsoft.data.mysql:3306` | `localhost:3306`
`postgres` | `postgres:5432` 或 `zongsoft.data.postgres:5432` | `localhost:5432`
`rustfs` | `rustfs:9000` 或 `zongsoft.io:9000` | `localhost:9000`、`localhost:9001`

MySQL 与 PostgreSQL 在该模式下使用不同的服务名和网络别名，可以同时启动。

容器访问 Windows 宿主机时使用 `host.containers.internal`。例如 Windows 服务监听 `8080` 端口，容器内使用：

```text
http://host.containers.internal:8080
```

`host` 服务默认使用 `http://host.containers.internal:1080` 作为网络代理，可以通过 `ZONGSOFT_HTTP_PROXY` 和 `ZONGSOFT_HTTPS_PROXY` 环境变量覆盖。

#### Compose 常用命令

```shell
# 查看日志
podman compose --file zongsoft.compose.yaml --project-name zongsoft logs host
podman compose --file zongsoft.compose.yaml --project-name zongsoft logs mysql
podman compose --file zongsoft.compose.yaml --project-name zongsoft logs postgres
podman compose --file zongsoft.compose.yaml --project-name zongsoft logs redis

# 进入容器
podman compose --file zongsoft.compose.yaml --project-name zongsoft exec host bash
podman compose --file zongsoft.compose.yaml --project-name zongsoft exec mysql bash
podman compose --file zongsoft.compose.yaml --project-name zongsoft exec postgres bash
podman compose --file zongsoft.compose.yaml --project-name zongsoft exec redis bash

# 直接启动指定服务
podman network exists zongsoft-net || podman network create zongsoft-net
podman compose --file zongsoft.compose.yaml --project-name zongsoft up --detach redis
podman compose --file zongsoft.compose.yaml --project-name zongsoft up --detach mysql
podman compose --file zongsoft.compose.yaml --project-name zongsoft up --detach postgres

# 停止服务但保留数据
podman compose --file zongsoft.compose.yaml --project-name zongsoft stop redis mysql postgres

# 删除本项目容器但保留匿名卷和共享网络
podman compose --file zongsoft.compose.yaml --project-name zongsoft down

# 删除本项目容器及匿名卷，保留共享网络
podman compose --file zongsoft.compose.yaml --project-name zongsoft down --volumes
```

### 两种模式的共同说明

#### 在两种模式之间切换

两种模式共享 `zongsoft-net`、Windows 宿主端口和部分网络别名。不要同时用两种模式启动同一个服务，否则会发生端口或网络名称冲突。

切换模式前，应先用当前模式对应的停止脚本关闭相关服务：

- 从 K8s Pod 切换到 Compose：运行 `zongsoft.pod(stop).cmd` 停止对应 Pod；
- 从 Compose 切换到 K8s Pod：运行 `zongsoft.compose(stop).cmd <service> --clean` 删除对应 Compose 容器。

#### Windows 与容器通讯

- Windows 访问基础服务：使用 `localhost` 和对应的映射端口；
- 容器访问 Windows：使用 `host.containers.internal`；
- 容器相互访问：使用当前模式文档中列出的 Pod 名、服务名或网络别名；
- 不要在配置中固定容器 IP，因为容器重新创建后 IP 可能变化。

#### 启动就绪时间

- `host` 容器首次启动时需要安装并初始化 `systemd`、`nginx` 等工具，容器显示运行后仍可能需要等待；
- MySQL 和 PostgreSQL 首次启动时需要执行建表及数据初始化 SQL，应等待初始化完成后再连接；
- 可以通过当前模式对应的日志命令确认初始化进度。

#### 默认开发凭据

服务 | 用户名或访问键 | 密码或密钥
-----|----------------|-----------
Redis | _无用户名_ | `xxxxxx`
MySQL | `program` | `xxxxxx`
PostgreSQL | `program` | `xxxxxx`
RustFS | `rustfsadmin` | `rustfsadmin`

这些凭据仅用于本地开发。Compose 模式可以通过 `ZONGSOFT_REDIS_PASSWORD`、`ZONGSOFT_MYSQL_PASSWORD`、`ZONGSOFT_POSTGRES_PASSWORD`、`ZONGSOFT_RUSTFS_ACCESS_KEY` 和 `ZONGSOFT_RUSTFS_SECRET_KEY` 环境变量覆盖默认值。
