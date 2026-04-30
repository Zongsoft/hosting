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

由于一些插件需要使用到 _**R**edis_、_**R**ust**FS**_、_**M**y**SQL**_ 或 _**P**ostgre**SQL**_ 等，因此可以容器化这些依赖的服务。

> 建议安装 _**P**odman_ _**CLI**_ 进行容器化处理，下面是它的下载地址：
> - https://podman.io
> - https://github.com/containers/podman/releases

> 💡 如果是 _**W**indows_ 环境，请确保安装了 [_WSL-2_](https://learn.microsoft.com/zh-cn/windows/wsl/install)。

### 网络模式

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

### 目录映射

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

### 镜像配置

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

### 容器文件

我们提供了一些 _**P**od_ 容器文件：
- [_zongsoft.pod-host.yaml_](./zongsoft.pod-host.yaml) 该文件定义了一个包含 _.NET SDK 10_ 以及 `systemd`、`nginx` 等开发环境的容器。
	> 💡 该容器定义了网络代理，你应该根据自己的实际情况编辑该文件中的代理设置。

- [_zongsoft.pod-redis.yaml_](./zongsoft.pod-redis.yaml) 该文件定义了 _**R**edis_ 分布式缓存容器。
- [_zongsoft.pod-rustfs.yaml_](./zongsoft.pod-rustfs.yaml) 该文件定义了 _**R**ust**FS**_ 分布式文件系统容器。

- [_zongsoft.pod-mysql.yaml_](./zongsoft.pod-mysql.yaml) 该文件定义了 _**M**y**SQL**_ 数据库容器，以及一个名为 `zongsoft` 的数据库 _（该库已初始化）_，确保开箱即用。
- [_zongsoft.pod-postgres.yaml_](./zongsoft.pod-postgres.yaml) 该文件定义了 _**P**ostgre**SQL**_ 数据库容器，以及一个名为 `zongsoft` 的数据库 _（该库已初始化）_，确保开箱即用。

请确保 [_hosting_](https://github.com/Zongsoft/hosting) 的同级位置有如下仓库，因为 `zongsoft` 数据库创建后会加载运行这些仓库中的 _SQL_ 脚本，以完成建表和数据初始化。

> - [adadministratives](https://github.com/Zongsoft/administratives)
> - [discussions](https://github.com/Zongsoft/discussions)
> - [framework](https://github.com/Zongsoft/framework)

### 操作步骤

使用 `zongsoft.pod(start).cmd` 和 `zongsoft.pod(stop).cmd` 脚本可以更方便的启用或停止指定的容器，并确保它创建的容器都共享同个网络。

1. 在 _文件管理器_ 中双击 `zongsoft.pod(start).cmd` 文件，或者在 _命令提示符_ 中运行该脚本文件；
	> 在提示中根据需要输入要启动的容器：
	> - `host` 启动 _宿主应用程序_ 的开发容器；
	> - `redis` 启动 _**R**edis_ 分布式缓存容器；
	> - `rustfs` 启动 _**R**ust**FS**_ 分布式文件容器；
	> - `mysql`  启动 _**M**y**SQL**_ 数据库容器；
	> - `postgres` 启动 _**P**ostgre**SQL**_ 数据库容器。

2. 使用下列命令检查 _Pod_ 是否成功运行

```shell
podman ps -a --pod
```

> - 💡 当 `host` 容器启动时会下载并初始化 _systemd_、_nginx_ 等基础服务，即使容器启动成功，而 _systemd_、_nginx_ 可能尚未准备就绪，建议稍等一会再进入 `podmapodman exec -it zongsoft-host bash` 容器虚拟机。
> 	- 通过 `podman logs zongsoft-host` 命令查看其启动日志以确定加载进度。

> - 💡 由于 _**M**y**SQL**_ 和 _**P**ostgre**SQL**_ 数据库容器在启动时会执行建表及初始化数据等 _SQL_ 操作，因此即使容器已显示启动成功，也建议稍等片刻再连接数据库，以确保相关 _SQL_ 脚本已执行完成。

3. 在 _文件管理器_ 中双击 `zongsoft.pod(stop).cmd` 文件，或者在 _命令提示符_ 中运行该脚本文件；
	> 在提示中根据需要输入要关闭的容器：
	> - `*` 关闭所有容器；
	> - `host` 关闭 _宿主应用程序_ 的开发容器；
	> - `redis` 关闭 _**R**edis_ 分布式缓存容器；
	> - `rustfs` 关闭 _**R**ust**FS**_ 分布式文件容器；
	> - `mysql`  关闭 _**M**y**SQL**_ 数据库容器；
	> - `postgres` 关闭 _**P**ostgre**SQL**_ 数据库容器。

#### 网络地址

在容器中如果需要连接到其他容器中的服务，需要使用连接服务容器的 _**P**od_ 名作为其连接的网络地址。

 _Pod_ 名 | 容器名
----------|------
`zongsoft`         | `zongsoft-host`
`zongsoft.io`      | `zongsoft.io-rustfs`
`zongsoft.data`    | `zongsoft.data-mysql`
`zongsoft.data`    | `zongsoft.data-postgres`
`zongsoft.caching` | `zongsoft.caching-redis`

1. 进入 `zongsoft-host` 容器：

	```shell
	podman exec -it zongsoft-host bash
	```

2. 连接到其他容器服务

	```shell
	# 访问 RustFS 的管理页面（网址为 RustFS 容器的 Pod 名）
	curl -L -A "Mozilla/5.0(Linux; x64)" http://zongsoft.io:9001

	# 连接 Redis 服务（连接地址为 Redis 容器的 Pod 名）
	redis-cli -h zongsoft.caching -p 6379
	```

3. 使用 _**R**edis_ 服务

	```shell
	zongsoft.caching:6379> auth xxxxxx
	OK
	zongsoft.caching:6379> get key
	(nil)
	```

### 常用命令

- 查看容器日志

	> ```shell
	> podman logs zongsoft-host
	> podman logs zongsoft.data-mysql
	> podman logs zongsoft.data-postgres
	> podman logs zongsoft.caching-redis
	> ```

- 进入指定容器的 _bash_

	> ```shell
	> podman exec -it zongsoft-host bash
	> podman exec -it zongsoft.data-mysql bash
	> podman exec -it zongsoft.data-postgres bash
	> podman exec -it zongsoft.caching-redis bash
	> ```

- 启动 _Pod_ 容器

	> ```shell
	> podman kube play --replace .\zongsoft.pod-redis.yaml
	> podman kube play --replace .\zongsoft.pod-mysql.yaml
	> podman kube play --replace .\zongsoft.pod-postgres.yaml
	> ```

- 关闭 _Pod_ 容器

	> ```shell
	> podman kube down .\zongsoft.pod-host.yaml
	> podman kube down .\zongsoft.pod-redis.yaml
	> podman kube down .\zongsoft.pod-mysql.yaml
	> podman kube down .\zongsoft.pod-postgres.yaml
	> ```

- 停止所有容器

	> ```shell
	> podman stop -a
	> ```

- 停止并移除所有容器及卷

	> ```shell
	> podman rm -afv
	> ```

- 删除本地映像

	> ```shell
	> podman rmi rustfs:latest
	> ```
