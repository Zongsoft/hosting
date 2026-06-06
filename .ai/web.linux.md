# Web 宿主编译、部署、打包与 Linux 安装验证工作流

## 目标

指导 AI Agent 完成 `web/default` 宿主项目的编译、部署、Linux 安装包制作，并将安装包发布到目标 Linux 系统的 `/opt` 目录中进行安装，最后验证安装结果、Web 服务运行状态和 Nginx 反向代理状态正常。

本工作流只面向 `web/default` 宿主项目。宿主程序本身不应加入业务代码，业务能力应由插件、配置和外部服务提供。

## 适用场景

- 需要发布默认 Web API 宿主到 Linux 服务器。
- 需要通过 `deploy.cmd` 一次性完成编译、插件部署和安装包制作。
- 需要把生成的安装包复制到本机 WSL Linux 或远程 Linux 服务器验证安装。
- 需要检查安装后的 systemd 服务、进程、监听端口、Nginx 配置和 HTTP 可访问性。

## 不适用场景

- 只修改文档且不需要执行构建、部署或安装验证。
- 需要实现业务功能；此时应优先查找插件、配置或外部业务代码。
- 只需要验证某个 Web API 行为；此时优先参考 `web/.http` 目录下的请求定义，或转换为 `curl` 调用。

## 操作原则

- 工作目录根路径：当前仓库根目录，以下用 `<repo-root>` 表示。
- 宿主项目目录：`<repo-root>\web\default`。
- 遵守仓库约定：保持已有文件换行符；新文件使用 CRLF；代码文件使用 Tab 缩进。
- 不要为了通过验证而修改宿主项目添加临时业务逻辑。
- `deploy.cmd` 是交互式脚本，会执行编译、部署和安装包制作。执行前应先确认参数和影响。
- 必须调用 `web/default/deploy.cmd` 完成编译、部署和打包，不允许自行编写脚本或拆出 `dotnet cake`、`dotnet deploy`、`dotnet-pack` 等底层命令绕过脚本。
- 必须让 `dotnet-pack` 按 `deploy.cmd`/`pack.cmd` 参数统一生成 systemd `.service` 文件；不要手写 `.service` 文件替代打包器行为。如果生成的服务文件有问题，应分析 `/Zongsoft/tools/packager` 项目源码并向用户报告原因。
- 未经明确要求，不运行 `deploy.cmd`、`pack.cmd`、`install.cmd`、`uninstall.cmd`、`upgrade.pack.cmd`、`upgrade.publish.cmd` 或容器启停脚本。
- 如果验证失败是因为插件、容器、`/Zongsoft/framework`、`/Zongsoft/tools` 或目标 Linux 环境缺失，应如实记录，不要绕过。

## 必须向用户确认的信息

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

| 格式 | 适用 Linux 分支 | `deploy.cmd` 输入 | 安装方式 |
| --- | --- | --- | --- |
| `.deb` | Debian、Ubuntu 及其衍生发行版 | `deb` | `apt install ./<package>.deb` 或 `dpkg -i` |
| `.rpm` | RHEL、CentOS、Rocky Linux、AlmaLinux、Fedora、openSUSE 等 RPM 系发行版 | `rpm` | `dnf install ./<package>.rpm`、`yum install` 或 `rpm -i` |
| `.tar.gz` | 通用 Linux 发行版，适合无包管理安装或手工验证 | `tar` | 解压到 `/opt` 后按包内说明注册服务 |

如果目标是本机 WSL Ubuntu，通常选择 `.deb`；如果目标是 RPM 系服务器，选择 `.rpm`；如果目标包管理器未知或只需展开验证，选择 `.tar.gz`。

## 人工操作步骤

### 1. 进入 `web/default` 目录

在 Windows 侧进入 Web 宿主目录：

```powershell
$repo = git rev-parse --show-toplevel
Set-Location (Join-Path $repo 'web/default')
```

### 2. 执行 `deploy.cmd` 脚本

执行脚本并根据提示输入用户确认过的参数：

```powershell
.\deploy.cmd
```

该脚本会完成三个阶段：

- 编译：通过 `dotnet cake` 命令执行。
- 部署：通过 `dotnet deploy` 命令执行。
- 打包/制作安装包：通过 `dotnet-pack` 命令执行。

脚本当前会询问以下内容：

- `scheme`：部署方案，空值默认为 `default`。
- `environment`：发布环境，空值通常回退到当前 `Environment` 环境变量或 `development`。
- `debug`：是否开启远程调试，空值默认为 `on`；正式 Linux 发布通常输入 `off`。
- `platform`：目标平台；制作 Linux 安装包时输入 `linux`。
- `architecture`：目标架构，空值默认为 `x64`。
- `framework`：目标框架，空值默认为 `net10.0`。
- `format`：安装包格式；按用户指定输入 `deb`、`rpm` 或 `tar`。如果用户指定 `.tar.gz`，脚本中输入 `tar`。
- `version`：安装包版本号，不能为空。
- `edition`：安装包版本标识，可按发布约定填写。

注意：如果只需要部署、不需要打包，可在脚本的打包格式提示处输入 `exit` 或 `quit` 退出打包阶段；但本工作流目标包含制作安装包，因此通常不应这样做。

### 3. 定位生成的安装包

脚本成功结束后，在 `web/default` 目录及其输出目录中查找新生成的安装包：

```powershell
Get-ChildItem -Path . -Recurse -File |
	Where-Object {
		$_.Name -like '*.deb' -or
		$_.Name -like '*.rpm' -or
		$_.Name -like '*.tar' -or
		$_.Name -like '*.tar.gz'
	} |
	Sort-Object LastWriteTime -Descending |
	Select-Object -First 20 FullName, Length, LastWriteTime
```

选择与本次 `format`、`version`、`architecture`、`framework` 匹配的包。Web 安装包名称通常包含 `Zongsoft.Web`、版本号、平台和架构。

### 4. 进入 Linux 服务器

如果指定的安装目的地是本机，则进入用户指定的 WSL 虚拟机。以下示例使用 Ubuntu，实际发行版名称以用户确认为准：

```powershell
wsl -d Ubuntu
```

如果安装目的地是远程 Linux 服务器，则通过 SSH 登录：

```powershell
ssh <user>@<host>
```

### 5. 将安装包拷贝到服务器的 `/opt` 目录

#### 本机 WSL Linux

`<repo-root-wsl-path>` 表示仓库根目录在 WSL 中的映射路径，可在 WSL 中用 `wslpath -a '<repo-root>'` 按实际仓库路径转换得到。然后在 WSL 中执行：

```bash
sudo mkdir -p /opt
sudo cp <repo-root-wsl-path>/web/default/<package-file> /opt/
cd /opt
ls -lh <package-file>
```

如果自动化环境中 `sudo` 需要密码，可改用 WSL 的 root 用户入口执行复制命令：

```powershell
wsl -d Ubuntu -u root -- bash -lc "mkdir -p /opt && cp '<repo-root-wsl-path>/web/default/<package-file>' /opt/ && ls -lh '/opt/<package-file>'"
```

#### 远程 Linux 服务器

先从 Windows 侧上传到临时目录，再移动到 `/opt`：

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

### 6. 执行安装

#### `.deb` 安装包

适用于 Debian、Ubuntu 及其衍生发行版：

```bash
cd /opt
sudo apt install -y ./<package-file>.deb
```

如果使用 `dpkg` 安装并出现依赖问题，执行：

```bash
sudo dpkg -i ./<package-file>.deb
sudo apt-get install -f -y
```

如果通过 `wsl -u root` 验证，可去掉 `sudo`：

```powershell
wsl -d Ubuntu -u root -- bash -lc "cd /opt && apt install -y './<package-file>.deb'"
```

如果目标 WSL 中已经安装过同版本 `zongsoft.web`，不要用 `apt install --reinstall` 作为验证路径；当前包脚本的旧包 `postrm` 会删除 `/opt/zongsoft/web`，可能把刚解包的新文件一并移除。验证同版本包时先卸载再安装：

```powershell
wsl -d Ubuntu -u root -- bash -lc "systemctl stop zongsoft.web 2>/dev/null || true; apt remove -y zongsoft.web || true; apt install -y '/opt/<package-file>.deb'"
```

#### `.rpm` 安装包

适用于 RPM 系发行版，例如 RHEL、CentOS、Rocky Linux、AlmaLinux、Fedora、openSUSE：

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

#### `.tar.gz` 安装包

如果本次制作的是 `.tar` 或 `.tar.gz` 包，按发布约定解压到 `/opt` 下的独立目录：

```bash
cd /opt
sudo mkdir -p /opt/zongsoft-web
sudo tar -xf ./<package-file> -C /opt/zongsoft-web
```

然后根据包内说明或随包脚本安装 systemd 服务。不要猜测覆盖现有服务；先查看包内容：

```bash
find /opt/zongsoft-web -maxdepth 3 -type f | sort | head -100
```

## Web 安装结果验证

### 1. 确认文件已安装

```bash
dpkg -L zongsoft.web 2>/dev/null || dpkg -L Zongsoft.Web 2>/dev/null || rpm -ql zongsoft.web 2>/dev/null || rpm -ql Zongsoft.Web 2>/dev/null || true
ls -lah /opt
ls -lah /Zongsoft/hosting/web/default 2>/dev/null || true
```

### 2. 查找并验证 systemd 服务

默认 Web 服务名通常为 `zongsoft.web`，但应以实际安装内容为准：

```bash
systemctl list-unit-files | grep -i zongsoft || true
systemctl list-units --type=service --all | grep -i zongsoft || true
systemctl cat zongsoft.web 2>/dev/null || true
```

启动或重启服务：

```bash
sudo systemctl daemon-reload
sudo systemctl enable zongsoft.web
sudo systemctl restart zongsoft.web
```

验证服务状态：

```bash
systemctl status zongsoft.web --no-pager
systemctl is-active zongsoft.web
```

期望结果：`is-active` 输出 `active`。

### 3. 验证监听端口和本机 HTTP

默认 Web 宿主监听 `127.0.0.1:8069`，安装包会把 Nginx 反向代理配置发布到 `/etc/nginx/conf.d/zongsoft.web.conf`。

```bash
ss -lntp | grep ':8069' || true
curl -i --max-time 10 http://127.0.0.1:8069/
```

如果根路径需要认证或返回业务错误，只要 HTTP 服务有响应且日志没有启动失败，可继续结合 `web/.http` 中的接口定义验证实际 API。

### 4. 验证 Nginx 配置和代理

安装包包含 Nginx 配置，并在安装后尝试执行 `reload-nginx.sh`。目标机器如果安装了 Nginx，应检查配置和代理端口：

```bash
test -f /etc/nginx/conf.d/zongsoft.web.conf && sudo nginx -t
sudo systemctl reload nginx 2>/dev/null || sudo nginx -s reload 2>/dev/null || true
curl -i --max-time 10 http://127.0.0.1:8080/
```

默认配置还包含 `server_name api.zongsoft.com` 的 80 端口代理。如需验证域名入口，应先确认 DNS 或本机 hosts 指向目标服务器：

```bash
curl -i --max-time 10 -H "Host: api.zongsoft.com" http://127.0.0.1/
```

如果目标系统未安装 Nginx，记录该事实；只要 `zongsoft.web` 服务和 `8069` 端口验证通过，可将 Nginx 验证标记为环境缺失而非宿主失败。

### 5. 查看最近日志

```bash
journalctl -u zongsoft.web -n 200 --no-pager
```

重点检查：

- 没有启动崩溃。
- 没有插件加载失败。
- 没有配置文件缺失。
- 没有端口 `8069` 绑定失败。
- 没有数据库、Redis、对象存储等基础服务连接失败；如果有，记录缺失依赖和连接目标。

### 6. 通过 HTTP 请求定义做补充验证

修改 Web API 相关内容后，可参考 `<repo-root>\web\.http` 目录下的请求定义，或将其转换为 `curl` 方式验证。

需要身份验证的接口通常通过 `Authorization` 头传递凭证。可读取 `.env` 中的真实凭证值用于调试，但不要在回复中原样暴露，必要时仅脱敏展示。

## Codex 自动化执行要求

本工作流的验证对象就是 `web/default/deploy.cmd`，因此自动化执行也必须调用该脚本。不要为了规避交互或控制台捕获问题而自行执行 `dotnet cake`、`dotnet deploy`、`dotnet-pack`，也不要写临时脚本模拟 `deploy.cmd` 的部分逻辑。

如果 Codex 或其他捕获式 shell 无法正常驱动 `deploy.cmd`，应切换到真实 Windows 控制台执行该脚本，或向用户报告当前环境无法完成有效验证；不要拆出底层命令继续执行。

## 验收标准

满足以下条件即认为本轮工作完成：

- 已向用户确认 `scheme`、`environment`、`platform`、`architecture`、安装包格式、目标 Linux、`framework`、`version` 和 `debug`。
- `deploy.cmd` 已成功完成编译、部署和安装包制作。
- 已明确记录安装包路径、文件名、版本号、格式和目标架构。
- 安装包已复制到目标 Linux 的 `/opt` 目录。
- 已按用户指定的安装包格式执行对应 Linux 分支的安装命令。
- `zongsoft.web` 或实际服务名已启动。
- Web 服务运行状态验证通过，服务处于 `active` 或符合预期的运行状态。
- `127.0.0.1:8069` 有 HTTP 响应。
- 如果目标系统安装了 Nginx，则 Nginx 配置检测通过，反向代理端口或域名入口有 HTTP 响应。
- 最近日志中没有阻断运行的错误。

## 失败处理

- 编译失败：记录 `dotnet cake` 输出中的首个有效错误，优先检查目标框架、SDK、框架源码或 NuGet 包是否可用。
- 部署失败：记录 `dotnet deploy` 输出，检查 `.deploy` 文件、`../../.deploy/<scheme>/` 配置和插件来源是否存在。
- 打包失败：记录 `dotnet-pack` 输出，检查包格式、版本号、目标平台、Nginx 文件和部署输出目录。
- 上传失败：检查网络、SSH 凭据、目标目录权限和磁盘空间。
- 安装失败：记录 `apt`、`dpkg`、`dnf`、`yum` 或 `rpm` 错误，检查包格式是否适配目标 Linux 分支及依赖是否可解析。
- 服务启动失败：记录 `systemctl status` 和 `journalctl` 日志，优先确认配置、插件、端口占用和基础服务依赖，不要向宿主项目加入临时代码绕过。
- 如果日志包含 `Zongsoft.Web.runtimeconfig.json was not found` 或 `libhostpolicy.so`，先检查安装后的 `.service` 文件是否由 `dotnet-pack` 生成了错误入口；不要修改 `web/default/deploy.cmd` 或手写 `.service` 绕过，应分析 `/Zongsoft/tools/packager` 项目源码并向用户报告。
- 如果日志包含 `Could not load type 'Zongsoft.Components.Version'`，优先怀疑 `plugins/` 中存在旧插件产物。处理方式是删除宿主项目的 `plugins/` 目录后重新执行 `deploy.cmd` 部署全新插件，不要手工覆盖单个插件作为发布验证路径。
- Nginx 验证失败：记录 `nginx -t` 输出，检查 `/etc/nginx/conf.d/zongsoft.web.conf`、端口占用、域名和代理目标 `127.0.0.1:8069`。

## 常见陷阱

| 陷阱 | 处理方式 |
| --- | --- |
| 未指定安装包格式 | 先确认用户要 `.deb`、`.rpm` 还是 `.tar.gz`，并核对目标 Linux 发行版。 |
| 为 Linux 选择了 `windows` 平台 | 在 `deploy.cmd` 的平台提示中输入 `linux`。 |
| 包格式与发行版不匹配 | Debian/Ubuntu 使用 `.deb`；RPM 系发行版使用 `.rpm`；通用展开验证使用 `.tar.gz`。 |
| `debug` 留空导致默认开启远程调试 | 正式 Linux 发布通常输入 `off`，确保 `compilation=Release`。 |
| `version` 留空导致打包中断 | 执行前先确认版本号，格式通常为 `major.minor.patch`。 |
| 找不到生成的安装包 | 按最后修改时间搜索 `.deb`、`.rpm`、`.tar`、`.tar.gz`，并核对版本和架构。 |
| systemd 服务名不确定 | 先用 `systemctl list-unit-files | grep -i zongsoft` 查找，不要猜测覆盖服务。 |
| `8069` 端口无响应 | 先检查 `zongsoft.web` 服务状态和日志，再检查端口占用与配置。 |
| Nginx 入口无响应 | 先验证 `127.0.0.1:8069`，再检查 `nginx -t`、Nginx 服务和代理配置。 |
| 启动失败但日志显示依赖不可用 | 记录缺失的数据库、Redis、对象存储或插件依赖，不要改宿主程序绕过。 |
| systemd 启动了 `Zongsoft.Web.dll` | 不要手写 `.service` 绕过；分析 `/Zongsoft/tools/packager` 的 systemd 生成逻辑，确认 `--daemon-bind`、包名和宿主入口推断规则，再向用户报告修复建议。 |
| 同版本 deb 重装后服务文件存在但 `/opt/zongsoft/web` 消失 | 不要用 `apt install --reinstall` 验证同版本包；先 `apt remove -y zongsoft.web`，再安装 `/opt/<package>.deb`。 |
| `Zongsoft.Components.Version` 类型加载失败 | 通常是 `plugins/` 中仍有旧插件；删除宿主 `plugins/` 目录后重新运行 `deploy.cmd`，确保全新部署插件。 |
| `dotnet-deploy` 或 `dotnet-pack` 抛出 `句柄无效` | 捕获式 shell 或输入重定向没有真实控制台句柄；切换真实 Windows 控制台运行 `deploy.cmd`，或报告环境阻塞，不要拆底层命令绕过脚本。 |
| WSL 中 `sudo` 等待密码导致命令超时 | 使用 `sudo -n true` 快速检测；本机验证可改用 `wsl -d <distro> -u root -- bash -lc "<command>"`。 |
| `apt install` 提示 `missing 'Description' field` | 这是 Debian control 元数据警告；只要退出码为 0 且服务验证通过，不视为安装失败。 |

## 结果回报模板

完成后向用户回报：

```text
web/default 安装验证结果：
- 部署方案：<scheme>
- 发布环境：<environment>
- 安装包：<package path>
- 目标系统：<local WSL Linux distro | remote Linux host and distro>
- 发布位置：/opt/<package-file>
- 安装方式：<apt install | dpkg | dnf | yum | rpm | tar>
- 服务名：<service-name>
- 服务状态：<active | failed | other>
- 本机端口：<8069 响应摘要>
- Nginx 入口：<通过 | 未验证 | 失败，原因>
- 日志摘要：<关键日志或错误>
- 结论：<通过 | 未通过，原因>
```
