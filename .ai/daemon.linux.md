# Daemon 宿主编译、部署、打包与 Linux 安装验证工作流

## 目标

指导 AI Agent 完成 `daemon` 宿主项目的编译、部署、Linux 安装包制作，并将安装包发布到目标 Linux 系统的 `/opt` 目录中进行安装，最后验证安装结果和运行状态正常。

本工作流只面向 `daemon` 宿主项目。宿主程序本身不应加入业务代码，业务能力应由插件和配置提供。

## 适用场景

- 需要发布 `daemon` 后台服务宿主到 Linux 服务器。
- 需要通过 `deploy.cmd` 一次性完成编译、插件部署和安装包制作。
- 需要把生成的安装包复制到本机 WSL Linux 或远程 Linux 服务器验证安装。
- 需要检查安装后的 systemd 服务、进程和日志。

## 不适用场景

- 只修改文档且不需要执行构建、部署或安装验证。
- 需要实现业务功能；此时应优先查找插件、配置或外部业务代码。
- 需要验证 Web API 行为；此时应优先参考 `web/.http` 或相关插件接口。

## 操作原则

- 工作目录根路径：当前仓库根目录，以下用 `<repo-root>` 表示。
- 宿主项目目录：`<repo-root>\daemon`。
- 遵守仓库约定：保持已有文件换行符；新文件使用 CRLF；代码文件使用 Tab 缩进。
- 不要为了通过验证而修改宿主项目添加临时业务逻辑。
- `deploy.cmd` 是交互式脚本，会执行编译、部署和安装包制作。执行前应先确认参数和影响。
- 必须调用宿主目录中的 `deploy.cmd` 脚本完成编译、部署和打包，不允许自行编写脚本或拆出 `dotnet cake`、`dotnet deploy`、`dotnet-pack` 等底层命令绕过脚本。
- 必须让 `dotnet-pack` 按脚本参数统一生成 systemd `.service` 文件；不要手写 `.service` 文件替代打包器行为。如果生成的服务文件有问题，应分析 `/Zongsoft/tools/packager` 并报告原因。
- 如果验证失败是因为插件、容器、`/Zongsoft/framework`、`/Zongsoft/tools` 或目标 Linux 环境缺失，应如实记录，不要绕过。

## 需要提前确认的信息

执行前向用户或任务上下文确认以下信息：

- 目标 Linux 发行版和版本：例如 Ubuntu、Debian、RHEL、CentOS、Rocky Linux、AlmaLinux、openSUSE。
- 目标安装位置：本机 WSL Linux，还是远程 Linux 服务器。
- 远程服务器连接信息：主机、端口、用户名、认证方式；本机 WSL 则确认发行版名称。
- 安装包格式：必须由用户指定，例如 `.deb`、`.rpm`、`.tar.gz`。不同格式适用于不同 Linux 分支。
- 部署方案 `scheme`，默认通常为 `default`。
- 环境名 `environment`：`development`、`test` 或 `production`，默认通常为 `development`。
- 是否开启远程调试 `debug`：`on` 或 `off`。
- 平台 `platform`：制作 Linux 安装包时必须为 `linux`。
- 架构 `architecture`：通常为 `x64`，也可能是 `arm64`。
- 目标框架 `framework`：例如 `net10.0`、`net9.0`、`net8.0`。
- 版本号 `version`：必须提供，格式通常为 `major.minor.patch` 或 `major.minor.patch.revision`。
- 打包版本标识 `edition`：可为空，也可按发布约定填写。
- 目标服务名：默认通常为 `zongsoft.daemon`，实际以安装包或 systemd 单元为准。

## 安装包格式选择

用户必须先指定安装包格式。不要替用户静默选择格式；如用户只说“发布到 Linux”，先确认目标发行版和包格式。

| 格式 | 适用 Linux 分支 | 安装方式 |
| --- | --- | --- |
| `.deb` | Debian、Ubuntu 及其衍生发行版 | `apt install ./<package>.deb` 或 `dpkg -i` |
| `.rpm` | RHEL、CentOS、Rocky Linux、AlmaLinux、Fedora、openSUSE 等 RPM 系发行版 | `dnf install ./<package>.rpm`、`yum install` 或 `rpm -i` |
| `.tar.gz` | 通用 Linux 发行版，适合无包管理安装或手工验证 | 解压到 `/opt` 后按包内说明注册服务 |

如果目标是本机 WSL Ubuntu，通常选择 `.deb`；如果目标是 RPM 系服务器，选择 `.rpm`；如果目标包管理器未知或只需展开验证，选择 `.tar.gz`。

## Windows 侧编译、部署和打包

### Codex 自动化执行要求

本工作流的验证对象就是宿主项目脚本，因此自动化执行也必须调用 `deploy.cmd`。不要为了规避交互或控制台捕获问题而自行执行 `dotnet cake`、`dotnet deploy`、`dotnet-pack`，也不要写临时脚本模拟 `deploy.cmd` 的部分逻辑。

如果 Codex 或其他捕获式 shell 无法正常驱动 `deploy.cmd`，应切换到真实 Windows 控制台执行该脚本，或向用户报告当前环境无法完成有效验证；不要拆出底层命令继续执行。

1. 进入 daemon 目录。

	```powershell
	$repo = git rev-parse --show-toplevel
	Set-Location (Join-Path $repo 'daemon')
	```

2. 执行 `deploy.cmd`。

	```powershell
	.\deploy.cmd
	```

3. 根据提示输入参数。

	脚本当前会询问以下内容：

	- `scheme`：部署方案，空值默认为 `default`。
	- `environment`：打包环境，空值通常回退到当前 `Environment` 环境变量或 `development`。
	- `debug`：是否开启远程调试，空值默认为 `on`。
	- `platform`：目标平台；制作 Linux 安装包时输入 `linux`。
	- `architecture`：目标架构，空值默认为 `x64`。
	- `framework`：目标框架，空值默认为 `net10.0`。
	- `format`：安装包格式；按用户指定输入 `deb`、`rpm` 或 `tar`。如果用户指定 `.tar.gz`，脚本中通常输入 `tar`。
	- `version`：安装包版本号，不能为空。
	- `edition`：安装包版本标识，可按发布约定填写。

4. 确认脚本完成三个阶段。

	- 编译：通过 `dotnet cake` 执行。
	- 部署：通过 `dotnet deploy` 执行。
	- 打包：通过 `dotnet-pack` 执行。

5. 定位生成的安装包。

	优先在 `daemon` 目录及其输出目录中查找新生成的安装包：

	```powershell
	Get-ChildItem -Path . -Recurse -File |
		Where-Object { $_.Extension -in '.deb', '.rpm', '.tar', '.gz' } |
		Sort-Object LastWriteTime -Descending |
		Select-Object -First 20 FullName, Length, LastWriteTime
	```

	选择与本次 `format`、`version`、`architecture`、`framework` 匹配的包。

## 发布到 Linux 的 `/opt`

### 本机 WSL Linux

如果安装目的地是本机，进入指定的 WSL Linux 发行版。以下示例使用 Ubuntu，实际发行版名称以用户指定为准：

```powershell
wsl -d Ubuntu
```

在 WSL 中创建发布目录，并将 Windows 侧安装包复制到 `/opt`。`<repo-root-wsl-path>` 表示仓库根目录在 WSL 中的映射路径，可在 WSL 中用 `wslpath -a '<repo-root>'` 按实际仓库路径转换得到：

```bash
sudo mkdir -p /opt
sudo cp <repo-root-wsl-path>/daemon/<package-file> /opt/
cd /opt
ls -lh <package-file>
```

如果自动化环境中 `sudo` 需要密码，可改用 WSL 的 root 用户入口执行复制和安装命令：

```powershell
wsl -d Ubuntu -u root -- bash -lc "mkdir -p /opt && cp '<repo-root-wsl-path>/daemon/<package-file>' /opt/ && ls -lh '/opt/<package-file>'"
```

### 远程 Linux 服务器

如果安装目的地是远程服务器，先从 Windows 侧上传到临时目录，再移动到 `/opt`：

```powershell
scp .\<package-file> <user>@<host>:/tmp/
ssh <user>@<host>
```

在远程 Linux 中执行：

```bash
sudo mkdir -p /opt
sudo mv /tmp/<package-file> /opt/
cd /opt
ls -lh <package-file>
```

## Linux 安装

### `.deb` 安装包

适用于 Debian、Ubuntu 及其衍生发行版。在目标 Linux 中执行：

```bash
cd /opt
sudo apt install -y ./<package-file>.deb
```

如果通过 `wsl -u root` 验证，可去掉 `sudo`：

```powershell
wsl -d Ubuntu -u root -- bash -lc "cd /opt && apt install -y './<package-file>.deb'"
```

如果使用 `dpkg` 安装并出现依赖问题，执行：

```bash
sudo dpkg -i ./<package-file>.deb
sudo apt-get install -f -y
```

### `.rpm` 安装包

适用于 RPM 系发行版，例如 RHEL、CentOS、Rocky Linux、AlmaLinux、Fedora、openSUSE。优先使用发行版包管理器安装：

```bash
cd /opt
sudo dnf install -y ./<package-file>.rpm
```

如果目标系统没有 `dnf`，可改用：

```bash
sudo yum install -y ./<package-file>.rpm
```

或在只需直接安装且依赖已满足时使用：

```bash
sudo rpm -i ./<package-file>.rpm
```

### `.tar.gz` 安装包

如果本次制作的是 `.tar` 或 `.tar.gz` 包，按发布约定解压到 `/opt` 下的独立目录：

```bash
cd /opt
sudo mkdir -p /opt/zongsoft-daemon
sudo tar -xf ./<package-file> -C /opt/zongsoft-daemon
```

然后根据包内说明或随包脚本安装 systemd 服务。不要猜测覆盖现有服务；先查看包内容：

```bash
find /opt/zongsoft-daemon -maxdepth 3 -type f | sort | head -100
```

## 安装结果验证

1. 确认文件已安装。

	```bash
	dpkg -L zongsoft.daemon 2>/dev/null || dpkg -L Zongsoft.Daemon 2>/dev/null || rpm -ql zongsoft.daemon 2>/dev/null || rpm -ql Zongsoft.Daemon 2>/dev/null || true
	ls -lah /opt
	```

2. 查找 systemd 服务单元。

	```bash
	systemctl list-unit-files | grep -i zongsoft || true
	systemctl list-units --type=service --all | grep -i zongsoft || true
	```

3. 启动或重启服务。

	将 `<service-name>` 替换为实际服务名：

	```bash
	sudo systemctl daemon-reload
	sudo systemctl enable <service-name>
	sudo systemctl restart <service-name>
	```

4. 验证服务状态。

	```bash
	systemctl status <service-name> --no-pager
	systemctl is-active <service-name>
	```

	期望结果：`is-active` 输出 `active`。

5. 查看最近日志。

	```bash
	journalctl -u <service-name> -n 200 --no-pager
	```

	重点检查：

	- 没有启动崩溃。
	- 没有插件加载失败。
	- 没有配置文件缺失。
	- 没有数据库、Redis、对象存储等基础服务连接失败；如果有，记录缺失依赖和连接目标。

6. 如服务未注册，检查进程和安装内容。

	```bash
	ps -ef | grep -i Zongsoft | grep -v grep || true
	find /opt -maxdepth 4 -iname '*zongsoft*' -o -iname '*.service'
	```

## 验收标准

满足以下条件即认为本轮工作完成：

- `deploy.cmd` 已成功完成编译、部署和安装包制作。
- 已明确记录安装包路径、文件名、版本号、格式和目标架构。
- 安装包已复制到目标 Linux 的 `/opt` 目录。
- 已按用户指定的安装包格式执行对应 Linux 分支的安装命令。
- systemd 服务或等效后台进程已启动。
- 运行状态验证通过，服务处于 `active` 或符合预期的运行状态。
- 最近日志中没有阻断运行的错误。

## 失败处理

- 编译失败：记录 `dotnet cake` 输出中的首个有效错误，优先检查目标框架、SDK、框架源码或 NuGet 包是否可用。
- 部署失败：记录 `dotnet deploy` 输出，检查 `.deploy` 文件、`../.deploy/<scheme>/` 配置和插件来源是否存在。
- 打包失败：记录 `dotnet-pack` 输出，检查包格式、版本号、目标平台和部署输出目录。
- 上传失败：检查网络、SSH 凭据、目标目录权限和磁盘空间。
- 安装失败：记录 `apt`、`dpkg`、`dnf`、`yum` 或 `rpm` 错误，检查包格式是否适配目标 Linux 分支及依赖是否可解析。
- 启动失败：记录 `systemctl status` 和 `journalctl` 日志，优先确认配置、插件和基础服务依赖，不要向宿主项目加入临时代码绕过。

## 常见陷阱

| 陷阱 | 处理方式 |
| --- | --- |
| 未指定安装包格式 | 先确认用户要 `.deb`、`.rpm` 还是 `.tar.gz`，并核对目标 Linux 发行版。 |
| 为 Linux 选择了 `windows` 平台 | 在 `deploy.cmd` 的平台提示中输入 `linux`。 |
| 包格式与发行版不匹配 | Debian/Ubuntu 使用 `.deb`；RPM 系发行版使用 `.rpm`；通用展开验证使用 `.tar.gz`。 |
| `version` 留空导致打包中断 | 执行前先确认版本号，格式通常为 `major.minor.patch`。 |
| 找不到生成的安装包 | 按最后修改时间搜索 `.deb`、`.rpm`、`.tar`、`.tar.gz`，并核对版本和架构。 |
| systemd 服务名不确定 | 先用 `systemctl list-unit-files | grep -i zongsoft` 查找，不要猜测覆盖服务。 |
| 启动失败但日志显示依赖不可用 | 记录缺失的数据库、Redis、对象存储或插件依赖，不要改宿主程序绕过。 |
| `dotnet-deploy` 或 `dotnet-pack` 抛出 `句柄无效` | 捕获式 shell 或输入重定向没有真实控制台句柄；切换真实 Windows 控制台运行 `deploy.cmd`，或报告环境阻塞，不要拆底层命令绕过脚本。 |
| WSL 中 `sudo` 等待密码导致命令超时 | 使用 `sudo -n true` 快速检测；本机验证可改用 `wsl -d <distro> -u root -- bash -lc "<command>"`。 |
| `apt install` 提示 `missing 'Description' field` | 这是 Debian control 元数据警告；只要退出码为 0 且服务验证通过，不视为安装失败。 |

## 结果回报模板

完成后向用户回报：

```text
daemon 安装验证结果：
- 安装包：<package path>
- 目标系统：<local WSL Linux distro | remote Linux host and distro>
- 发布位置：/opt/<package-file>
- 安装方式：<apt install | dpkg | dnf | yum | rpm | tar>
- 服务名：<service-name>
- 运行状态：<active | failed | other>
- 日志摘要：<关键日志或错误>
- 结论：<通过 | 未通过，原因>
```
