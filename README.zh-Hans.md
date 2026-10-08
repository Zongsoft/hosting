[English](./README.md) | [简体中文](./README.zh-Hans.md)

-----

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

在对应宿主目录中运行 Windows 交互脚本 `deploy.cmd`，执行构建及部署文件 _(`*.deploy`)_ 定义的部署内容，再选择是否制作安装包。本仓库提供 `daemon`、`terminal`、`web/default` 三套脚本。

> 提示：部署脚本依赖 **Z**ongsoft.**T**ools.**D**eployer 工具进行部署操作，有关该工具的使用说明，请参考其开源项目的相关文档：
> - 英文：[https://github.com/Zongsoft/tools/blob/main/deployer/README.md](https://github.com/Zongsoft/tools/blob/main/deployer/README.md)
> - 中文：[https://github.com/Zongsoft/tools/blob/main/deployer/README.zh-Hans.md](https://github.com/Zongsoft/tools/blob/main/deployer/README.zh-Hans.md)

`web/default`、`daemon` 和 `terminal` 的 `deploy.cmd` 统一使用 `--overwrite:newest`、`--prerelease:true` 和 `--verbosity:quiet`，允许选择仅提供预发布版本的插件依赖；可选文件缺失时跳过并输出警告。编译或部署返回失败时停止后续流程，不进入打包阶段。daemon 的构建、部署或打包失败时会显示失败阶段和退出码，并等待按键后退出。daemon 和 terminal 的插件部署到 `bin/<编译配置>/<目标框架>/plugins`。

各宿主的 `deploy.cmd` 和 `pack.cmd` 均以脚本所在目录为工作目录，也可从其它目录调用。构建、部署、Web 插件清理及打包路径仍基于对应宿主；正常结束、失败或跳过打包时均恢复调用者的目录和环境。

`deploy.cmd` 和 `pack.cmd` 调用部署、打包工具时均省略 `--framework`，由工具从合并后的 Variables 中读取 `framework`。在 hosting 根目录的 `.env` 中定义 `framework`，即可统一各宿主的部署、打包框架。两个脚本均不再询问框架；所有宿主的 `deploy.cmd` 调用 Cake 时也省略 `--framework`，使用各宿主 `build.cake` 的默认值。Cake 不读取 `.env`，应保持构建框架与部署、打包使用的框架一致。具体设置方式见下文“安装包与升迁包”。

每个宿主的 `deploy.cmd` 与 `pack.cmd` 使用相同的载荷和服务定义。部署后打包沿用本次构建配置和架构；独立 `pack.cmd` 另行询问这些参数，不执行编译或插件部署。daemon 显式使用 `--daemon:zongsoft.daemon` 由打包器生成服务，terminal 保持 `--daemon:disabled`；两者的应用名称分别保持 `zongsoft.daemon`、`zongsoft.terminal`，与各自 `.version` 和运行时应用名一致。`--title` 分别为 `Zongsoft.Daemon`、`Zongsoft.Terminal`。Web 的 Nginx 配置由 `--web:nginx` 生成。
各宿主均以所选环境值传入 `Environment` 和 `DOTNET_ENVIRONMENT`，并在 `--daemon-environments` 中声明这两个变量；Web 还传入并声明 `ASPNETCORE_ENVIRONMENT`。daemon 和 Web 生成的服务会写入这些变量。terminal 的独立 `pack.cmd` 也会询问环境，未输入且未继承已有值时默认为 `development`。

### 本地插件验证与常见启动问题

业务功能通过插件及配置接入，宿主 Program 不需要引用每个实现类。业务代码优先依赖 Core/模块公共接口，通过 `ApplicationContext.Current.Services`、应用自定义的 `Module.Current.Services` 或配置选定的提供者取得实现。完整示例见 [Core 服务定位](https://github.com/Zongsoft/framework/blob/main/Zongsoft.Core/README.zh-Hans.md)与[插件部署指南](https://github.com/Zongsoft/framework/blob/main/Zongsoft.Plugins/README.zh-Hans.md)。

1. 准备独立部署目录，确认清单与启动工作器，仅放入所需插件和测试配置。
2. 构建或发布相容的启动器；复制调试输出时保留 `*.deps.json`、`*.runtimeconfig.json`、依赖 DLL、`runtimes/` 及资源目录，不能只复制主 DLL。
3. 从部署目录运行。默认内容根取决于工作目录；在其它目录执行 DLL 的绝对路径，不会自动把内容根切换到 DLL 所在目录，可能报告 `plugins` 不存在。
4. Windows 终端宿主需要有效控制台句柄。交互式终端或 PTY/ConPTY 可用；无控制台的管道启动可能报“句柄无效”。后台无人值守场景使用 daemon/Web 启动器。
5. 先验证插件列表、配置读取与服务定位，再连接授权的本地基础设施。记录预期与实际结果，不打印凭据或业务数据。
6. 用 `exit -yes` 退出终端宿主；仅清理本次验证的数据和自行启动的资源。

🚨 插件加载成功不等于运行依赖齐全。宿主 Core 过旧可能在服务扫描时报程序集找不到；缺少 `runtimes` 会导致平台依赖加载失败；共享 SDK 被传递依赖覆盖则可能在第一次调用时报缺少方法。保留第一条错误，核对**最终部署文件**而不是只看项目引用或构建成功。

终端启动代码附加 `host=terminal`、`site=daemon`。这些值参与运行时选项选择；部署器的 `--site` 与宿主启动参数属于不同阶段。

最小 HTTP 验证见[解耦 Web 插件示例](https://github.com/Zongsoft/framework/blob/main/Zongsoft.Plugins.Web/README.zh-Hans.md)。控制器发现不会补出缺失的路由模板：默认宿主使用 `MapControllers()`，应检查实际响应而不仅是插件列表。手工部署原生插件时，保留 `runtimes/` 可能是必要条件，却不一定足够；还要核对原生搜索布局。Windows x64 SQLite 探针需要让匹配架构的 `e_sqlite3.dll` 位于 SQLite 托管组件旁。

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

- `certificates` 证书文件目录（可选）
	> 注：部署平台无关的证书文件。

- `{scheme}` 部署方案
	- `options` 配置文件目录
	- `migration` 升迁输入目录
		> `<版本>/*.migration` 引用 SQL 或声明 Amazon S3 桶；同目录或父目录的 `.ini` 提供升迁连接参数。

`certificates` 为按需添加的证书目录；当前默认方案包含 `options/` 和 `migration/`。hosting 根目录的 `.env` 为工具提供共享变量，`.migration/` 存放制作完成的升迁归档与启动脚本，各宿主的 `.packages/` 存放安装包。

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

## 安装包与升迁包

### 准备工具和共享变量

安装包由 [packager](https://github.com/Zongsoft/tools/tree/main/packager) 的 `dotnet-pack` 制作；升迁归档由独立 [migrator](https://github.com/Zongsoft/tools/tree/main/migrator) 的 `dotnet-migrate` 制作。按需安装或更新对应全局工具：

```powershell
dotnet tool install -g Zongsoft.Tools.Packager
dotnet tool install -g Zongsoft.Tools.Migrator
# 已安装时使用 dotnet tool update -g <工具包名>
```

在 hosting 根目录 `.env` 的根层设置 `framework`，例如：

```ini
framework=net10.0
```

工具依次合并默认值、进程环境变量、从文件系统根到源目录（migrator 为工作目录）的 `.env` 和显式命令选项，后者覆盖前者。`framework` 未指定或为 null/空字符串时从 Variables 取值；纯空白不按空值处理。`.env` 中 `[mysql] root_password` 等段落条目转换为 `mysql_root_password` 这样的变量名，再供升迁 `.ini` 引用。

在当前 PowerShell 窗口中准备部署用的环境变量，再进入目标宿主目录：

```powershell
$env:Environment = 'development'
Set-Location D:/Zongsoft/hosting/daemon
.\deploy.cmd
```

当前三个 deploy.cmd 的环境提示仍暂存到 value，应在启动前设置进程 Environment；独立 pack.cmd 已直接接受环境输入，留空保留进程 `Environment`，未继承已有值时默认为 `development`。

### 容器交付

制作工具通过既有 Profile 变量流程复用 hosting 根目录的 `.env`。在 .container 清单和模板中使用显式变量引用即可复用配置；CMD 不解析 .env，也不导出凭据。

内置 MySQL 模板将 `.env` 的 `[mysql] root_password` 映射到 `MYSQL_ROOT_PASSWORD`。组件中的显式 `settings=root-password=...` 或 `environment!MYSQL_ROOT_PASSWORD=...` 可覆盖它；其它设置仍需显式变量引用或模板绑定。

另行安装或更新全局 `Zongsoft.Tools.Containerizer` 工具。`containerize.cmd` 直接调用 PATH 上的 `dotnet-containerize`，不探测工具位置；本地编译及全局安装方式见 [制作工具 README](https://github.com/Zongsoft/tools/tree/main/containerizer)。

执行 `.\containerize.cmd`，可选择完整制作、`plan`（只生成可编辑清单）、`make`（依据清单制作）或 `run`（本机预演交付包）。新建选择保留原有发行版、架构和引擎菜单；脚本不逐项询问服务参数。在 `.containerized/.settings` 维护默认设置，需要本次单独调整时编辑生成的 `.container`。

```cmd
containerize.cmd plan
containerize.cmd make .containerized\zongsoft@1.0-x64.container
containerize.cmd plan .containerized\zongsoft@1.0-x64.container --version:1.1
containerize.cmd make .containerized\zongsoft@1.0-x64.container --version:1.1
```

使用 `containerize.cmd --refresh` 进入原菜单，可在本次完整制作或 make 中重新准备公共运行环境；plan/run 不刷新，无参数仍默认复用。也可直接执行 `containerize.cmd make FILE.container --version:1.1 --refresh`。选项不写入 `.container`，不修改基础服务固定摘要；应用安装包仍每次重新制作镜像。


最后两行是制作新发行版的两种替代方式。子命令后提供输入及选项时直接执行，跳过新建提示；单独传入 `.container` 仍作为 make 简写。交互 make 按文件名排序列出 `.containerized` 目录中的全部 `*.container` 文件（不递归子目录），最后一项为手动输入路径；只有选择末项才询问路径，没有找到文件时仅显示该项。选定清单后，可输入新的发行版本。直接运行 `containerize.cmd make` 且未提供路径时也显示此菜单。沿用清单保存的选择；交互脚本只允许版本和引擎选择覆盖清单。source 固定为 hosting 目录，output 固定为 `.containerized`；脚本退出时恢复调用者目录及环境。

完整制作、plan 或 make 执行结束后，脚本显式显示成功提示，或失败提示及工具原始退出码，并保留工具的具体诊断输出。成功与失败均等待按键后结束，命令窗口会保留，便于检查结果。

脚本按操作选择、交付设置、输入与执行结果分区显示。标题使用加粗青色，辅助说明与按键提示使用灰色，菜单选中行带背景高亮；成功、告警、错误分别使用绿、黄、红色并带明确状态标记。默认值/按键说明显示在文本输入项下方，并与字段名左侧对齐，光标紧跟字段名和冒号后的空格（例如 `Application name: `）；按 Enter 进入下一项，连续输入项之间保留一个空行。重定向输出保持纯文本，控制台中可设置 `NO_COLOR` 禁用脚本颜色。方向键、Esc 返回、字面路径、直接传参及工具退出码沿用既有行为。

新建交付物时，升迁目录菜单提供三个选项：无升迁（默认）、hosting 目录下的 `.migration`、手动输入。手动输入留空或仅输入空白也表示不启用升迁；输入时按 Esc 返回该菜单。

新建默认应用名 `zongsoft`、Debian 13、x64、自动引擎以及离线 bootstrap/镜像。发行版本留空使用日期版本；已有交付包不覆盖。事先用 deploy.cmd/pack.cmd 准备安装包，以 migrate.cmd 准备升迁；脚本不编译宿主，也不制作升迁。组件可输入 redis 等模板标识、安装包文件，以及 daemon、web/default 等目录。

镜像交付方式使用 `--imaging:online|offline`，对应 `.container` 根部及服务段落的 `imaging`；`bootstrap` 仍独立控制引擎依赖。旧 `--mode` 作为未知命令选项被忽略；根部/服务段落的 `mode` 条目不再接受。

`.containerized/.settings` 替换基础服务的 `.version`（与应用安装包自身的 `.version` 无关）。保留已有镜像 tag，Redis、MySQL 和 RustFS 密码引用根 `.env` 的变量。Redis 默认持久存储及 RDB/AOF 双持久化；某次测试可在 plan 清单中改用 `storage=temporary;persistence=none`。共享配置不复制密码值；选用其他服务时仍需填写它们的必填参数。

Web 安装包的 Nginx 监听来自包内 `.web/nginx/.bindings`。未填写端口覆盖时发布所有受支持的监听，包内声明 80 与 8080 时两者都会发布。Nginx 使用 `settings=port=80:18080,443:none`：容器 80 优先映射到宿主 18080，443 仅保留内部监听。已有 `.container` 必须直接采用此语法，Nginx 不接受 `port=127.0.0.1:80`。修改 `.settings` 不会改变已保存的清单。

`plan` 只生成 `name[-tag]@version-architecture.container`，不访问引擎、不解析镜像摘要。缺少必填参数时以紫红色告警并正常保存草稿，make 前补齐。`make` 不重新读取公共 `.settings`，在制作时展开变量；成功后才发布完整清单及 `.tar.gz`，失败保留编辑后的草稿。包内包含中英文 README 和相同完整清单。共享设置可纳入版本管理，生成归档继续忽略。

交互 run 列出 hosting 根目录 `.containerized/*.tar.gz`，末项手工输入路径。Esc 从手工输入退回文件选择，再退回操作菜单。`containerize.cmd run FILE.tar.gz [--engine:podman]` 直接执行，不附加制作选项、不询问版本。工具显示实际本机 Web/TCP 映射及尚未探测局域网可达性的网卡地址；请保留窗口，按 Ctrl+C 删除环境及测试数据。首次准备底图可能联网；Web 请求引擎按所有 IPv4 接口发布，局域网接入还取决于宿主/虚拟机转发和防火墙；Web 探测定向连接实际本机映射，保留 Host/SNI 和证书验证。已验证平台及失败检查方式见制作工具的 run 文档。

制作分支不执行现场安装或服务管理；run 分支在可清理的本机验证容器内安装。健康检查只证明进程/监听存活，不代表业务就绪；部署组合的验收范围见制作工具说明。

### 部署后打包或独立打包

从目标宿主目录运行 `deploy.cmd`，依次选择方案（默认 `default`）、环境、远程调试、平台和架构。远程调试默认 `on`，对应 Debug/Windows；`off` 对应 Release/Linux，可在后续平台提示中调整。用于 Linux 安装验证时选择 `off`、`linux` 及匹配的架构。构建或部署失败会停止后续流程。Web 部署还会先清理站点的 `plugins/`。

部署成功后，在格式提示中输入 `tar`、`deb` 或 `rpm` 制作安装包；输入 `exit` 或 `quit` 跳过打包，此分支当前返回退出码 `1`，不会触发 daemon 的失败暂停。直接运行 `pack.cmd` 则只打包已有文件：

```powershell
Set-Location D:/Zongsoft/hosting/web/default
.\pack.cmd
```

| 独立 `pack.cmd` 参数 | 默认或行为 |
| --- | --- |
| 格式 | `tar`；也支持 `deb`、`rpm`，三者均设置目标平台为 Linux |
| Edition、版本 | 可留空，按宿主源目录直属 `.edition`（优先）或 `.version` 确定；Edition 与 Debug/Release 编译配置不同 |
| 环境 | 见上文；写入 `Environment`、`DOTNET_ENVIRONMENT`，Web 另有 `ASPNETCORE_ENVIRONMENT` |
| 编译配置 | `Release`；可选 `Debug`，必须对应现有输出 |
| 架构 | `x64`；可选 `arm64`，必须与程序和升迁执行器匹配 |
| 方案 | 仅 Web 的独立脚本询问，默认 `default`；该脚本只打包现有部署文件，不重新应用方案 |
| 升迁输入名称或路径（`--migration`） | 留空跳过；如 `zongsoft`，详见下文 |

| 宿主 | 应用名 / 服务 | 载荷与默认安装目录 |
| --- | --- | --- |
| daemon | `zongsoft.daemon` / `zongsoft.daemon.service` | 展平 `bin/$(compilation)/$(framework)`；安装到 `/opt/zongsoft/daemon` |
| terminal | `zongsoft.terminal` / 禁用服务 | 展平同样的构建目录；安装到 `/opt/zongsoft/terminal` |
| web/default | `Zongsoft.Hosting.Web` / `zongsoft.web.service` | MIME、配置、wwwroot、plugins 及展平的构建目录；安装到 `/opt/zongsoft/web`，应用监听 `127.0.0.1:8069` |

所有脚本排除 `logs/`；Web 还排除构建目录中的 `*.staticwebassets.*`。`:~` 表示把所选目录的内容展平到安装根，不保留原来的 `bin/...` 层级。Web 的服务与 Nginx 配置详见 [Web README](web/README.zh-Hans.md#默认站点打包)。terminal 禁用 systemd 服务，因此 `--daemon-environments` 不会给交互式运行的终端设置进程环境。

输出位于所选宿主的 `.packages/`，如 `zongsoft.daemon@1.0.0-x64.deb`；Edition 非空时追加到包名。tar 生成同名 `.tar.gz` 和 `.sh` 安装入口，须配套保留；deb/rpm 各生成一个包文件。脚本未启用 `--overwrite`，同名产物已存在时制包失败。

制包成功后，源目录存在 `.edition` 时同时回写 `.edition` 和 `.version`（缺失则创建），只有 `.version` 时只更新它，两者均无时成组创建。安装包内始终包含最终身份的 `.version`，不交付源目录直属 `.edition`。安装和升级安装包是另外的操作，脚本不会自动安装。

### 先制作升迁包，再集成安装包

在 hosting 根目录运行 `migrate.cmd`，依次填写升迁名称（默认 `zongsoft`）、可选 Edition、必填版本号/版本文件/目录、平台（默认 `linux`）、架构（默认 `x64`）和方案（默认 `default`）。首次输入路径时留空会使用 `.deploy/$(scheme)/migration/$(version)/*.migration`；也可连续指定文件，之后留空结束。无目录分隔符的文件名基于该方案和版本目录定位，带目录的相对路径基于 hosting 根目录。裸 `*` 不接受，须用 `*.migration`。

升迁脚本与 `containerize.cmd` 使用一致的样式：标题加粗青色，字段标签青色，辅助提示灰色；成功、告警、错误分别使用绿、黄、红色的 `[OK]`、`[WARN]`、`[ERROR]` 标记。辅助提示显示在文本输入项下方，并与字段名左侧对齐，光标紧跟字段名和冒号后的空格，按 Enter 进入下一项；连续输入项之间保留一个空行。重定向输出保持纯文本，可设置 `NO_COLOR` 禁用脚本颜色。成功后正常结束；失败时保留工具诊断、等待按键并返回原始退出码。

例如在 hosting 根目录制作默认输入的 Linux x64 升迁包：

```powershell
dotnet-migrate --name:zongsoft --version:1.0.0 --platform:linux --architecture:x64 --scheme:default --output:.migration '.deploy/$(scheme)/migration/$(version)/*.migration'
```

生成 `.migration/zongsoft(migrate)@1.0.0_linux-x64.tar.gz` 与同名 `.sh`。Windows x64 生成对应 `win-x64` 归档与 `.cmd`；Linux 另支持 arm64。制作只解析输入、展开变量并打包，不连接或修改数据库/桶；脚本没有覆盖开关，重新制作同名产物需直接调用工具并明确添加 `--overwrite`。

默认版本目录包含 MySQL 与 Amazon S3 输入，连接参数位于 `.deploy/default/migration/*.ini`。升迁包根部直接包含 `migration.json`、`id`、内部启动入口、原生执行器和依赖，SQL 位于 `.artifacts/mysql/`，不套 `.migration` 目录。

随后在宿主 `deploy.cmd` 或 `pack.cmd` 的升迁提示中填写 `zongsoft`，脚本通过 `--migration` 将此输入传给 `dotnet-pack`。打包器从宿主源目录逐级查找父目录及各层直属 `.migration/`，按最终 Edition、版本和 RID 查找配套文件；两者必须来自同一位置并完整匹配。带目录的输入只定位指定目录，如 daemon 下的 `../.migration/zongsoft` 或 Web 下的 `../../.migration/zongsoft`。该选项不会自动制作升迁包。

安装包把归档和外部启动脚本原样放入安装根 `.migration/`；执行时脚本解压到独立临时目录，计划和执行器直接位于临时目录根部，执行结束后清理。安装时运行 `apply`，状态保存在 `/var/lib/<包名>/packager`，升迁失败阻止服务启动；systemd 启动前运行 `check` 比较本地成功标记。terminal 即使禁用 daemon，也会在安装时执行所集成的升迁。SQL 的重复执行由脚本自身保证幂等。

### 包元数据与依赖

当前 hosting 脚本没有单独的主页、厂家、维护者或依赖提示。可在工具读取的 `.env` 根层定义 `homepage`、`manufacturer`、`maintainer`、`dependencies`，或直接调用 `dotnet-pack` 传入对应选项。主页选项为 `--homepage`；厂家 `--manufacturer` 和维护者 `--maintainer` 默认均为 `Zongsoft`。厂家为 null/空字符串时也使用默认值，纯空白保留。

deb/rpm 的 `--dependencies` 统一采用 `name[:range]`，例如 `--dependencies:"aspnetcore-runtime-10.0:[10.0,11.0)"` 或 `--dependencies:"aspnetcore-runtime-10.0:[10.0)"`。区间外的逗号/分号表示同时依赖，`|` 表示任选一个；打包器分别转换为 Debian `Depends` 和 RPM `Requires`，不自动映射发行版包名。RPM 的替代依赖要求 4.13+，双边范围要求 4.14+。具体规则见 packager 的双语 README。

`upgrade.pack.cmd` / `upgrade.publish.cmd` 使用 `dotnet-upgrade` 制作和发布自动升级产物，与上述 Linux 安装包、升迁包流程独立；升级打包脚本仍询问 framework，不适用 `deploy.cmd` / `pack.cmd` 的框架提示约定。

## 容器化

由于一些插件依赖 Redis、RustFS、MySQL、PostgreSQL、Etcd、ClickHouse 或 TDengine，因此本项目同时支持两种基于 _**P**odman/**D**ocker_ 的本地容器化模式。两种模式地位相同，均包含开发宿主和基础服务；Compose 还定义了 ClickHouse 与 TDengine。用户可以根据工具习惯与数据生命周期需求选择。

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

容器化工具制作及本机 `run` 使用 `.containerized/.mirrors` 中显式配置的镜像源。例如：

```ini
docker.io=docker.m.daocloud.io
mcr.microsoft.com=mcr.m.daocloud.io
quay.io=quay.m.daocloud.io
```

一个仓库可以配置多个镜像源，以分号分隔，按顺序尝试。工具先复用符合摘要与架构要求的本地缓存，再尝试镜像源，最后尝试原仓库；确定摘要后不会在切换来源时更换镜像。默认制作和 `make` 从最终输出目录读取该文件，`run` 从所选交付包所在目录读取；`plan` 不访问镜像仓库。该文件不写入 `.container` 或交付包，也不会修改 Podman/Docker 的全局配置。不配置时沿用引擎已有行为。镜像源不解决 APT/DNF 软件包源及失效的网络代理问题。

上面的公共镜像源是本目录明确选择的配置，工具不内置或自动启用它们。 `.mirrors` 已补齐 [DaoCloud 官方清单](https://github.com/DaoCloud/public-image-mirror) 的 11 个 Registry；新增项使用上游推荐的 `m.daocloud.io/<源仓库>` 前缀，原有三个别名保留。`k8s.gcr.io` 是旧入口，`registry.ollama.ai` 在上游标为实验性。使用其他镜像源时填写 `主机[:端口][/路径前缀]`，不包含协议、tag、digest 或凭据。

直接运行 Podman、K8s Pod 或 Compose 时，如需全局镜像源，可手工配置 Podman 虚拟机，步骤如下：

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
	  location = "docker.io"
	[[registry.mirror]]
	  location = "docker.m.daocloud.io"

	[[registry]]
	  location = "mcr.microsoft.com"
	[[registry.mirror]]
	  location = "mcr.m.daocloud.io"

	[[registry]]
	  location = "quay.io"
	[[registry.mirror]]
	  location = "quay.m.daocloud.io"
	```

	每个 `[[registry.mirror]]` 属于它前面的 `[[registry]]`；MCR 必须有独立的 `[[registry]]`，不能作为 Docker Hub 的镜像源。镜像源条目中不填写 `prefix`。

3. 退出并重启虚拟机
	```shell
	podman machine stop
	podman machine start
	```

#### 网络代理

下面以 v2rayN 的 `10808` 混合代理端口为例。请确保 Windows 上的 v2rayN 正在运行，并开启“允许来自局域网的连接”，使 NAT 模式的虚拟机能够访问宿主机代理。如果 `/etc/environment` 或 `/etc/profile.d/proxy.sh` 已有旧代理配置，也应同步更新端口；HTTP 和 HTTPS 的代理地址均可使用 `http://<Windows宿主地址>:10808`。

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
PROXY="socks5h://${WIN_HOST}:10808"
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
`clickhouse` | ClickHouse 分析数据库，初始化 `zongsoft` 数据库及 `program` 账号
`tdengine` | TDengine 时序数据库
`rustfs` | RustFS 分布式文件系统

Compose 容器名称由 Compose 生成，日常操作应使用稳定的服务名，不要依赖具体容器名。

#### 启动 Compose 服务

在文件资源管理器中双击 `zongsoft.compose(start).cmd`，或者直接传入服务名：

```cmd
zongsoft.compose(start).cmd redis
zongsoft.compose(start).cmd mysql
zongsoft.compose(start).cmd clickhouse
zongsoft.compose(start).cmd tdengine
zongsoft.compose(start).cmd "*"
```

支持 `host`、`etcd`、`redis`、`mysql`、`postgres`、`clickhouse`、`tdengine`、`rustfs` 和 `*`；其中 `*` 表示启动 `zongsoft.compose.yaml` 中的全部服务。

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
`clickhouse` | `clickhouse:8123` 或 `zongsoft.data.clickhouse:8123` | `localhost:8123`
`tdengine` | `tdengine:6030`/`tdengine:6041` 或 `zongsoft.data.tdengine` | `localhost:6030`、`localhost:6041`
`rustfs` | `rustfs:9000` 或 `zongsoft.io:9000` | `localhost:9000`、`localhost:9001`

MySQL 与 PostgreSQL 在该模式下使用不同的服务名和网络别名，可以同时启动。

ClickHouse 首次初始化会创建 `zongsoft` 数据库和 `program` 账号；应用数据表需另行创建。TDengine 默认使用 `root` 账号，不会自动创建 `web/default/web.option` 配置的 `zongsoft` 数据库及 `program` 账号；使用该连接前应先建库、建账号。Windows 上使用 6030 端口的 TDengine 原生客户端时，`tdengine` 必须能解析到容器端点；6041 端口的 HTTP/WebSocket 接口不需要原生客户端的端点解析。

容器访问 Windows 宿主机时使用 `host.containers.internal`。例如 Windows 服务监听 `8080` 端口，容器内使用：

```text
http://host.containers.internal:8080
```

`host` 服务默认直连网络；需要网络代理时可设置 `ZONGSOFT_HTTP_PROXY` 和 `ZONGSOFT_HTTPS_PROXY` 环境变量。

#### Compose 常用命令

```shell
# 查看日志
podman compose --file zongsoft.compose.yaml --project-name zongsoft logs host
podman compose --file zongsoft.compose.yaml --project-name zongsoft logs mysql
podman compose --file zongsoft.compose.yaml --project-name zongsoft logs postgres
podman compose --file zongsoft.compose.yaml --project-name zongsoft logs clickhouse
podman compose --file zongsoft.compose.yaml --project-name zongsoft logs tdengine
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
podman compose --file zongsoft.compose.yaml --project-name zongsoft up --detach clickhouse
podman compose --file zongsoft.compose.yaml --project-name zongsoft up --detach tdengine

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
MySQL | `root` | `xxxxxx`
PostgreSQL | `program` | `xxxxxx`
ClickHouse | `program` | `xxxxxx`
TDengine | `root` | `taosdata`
RustFS | `rustfsadmin` | `rustfsadmin`

这些凭据仅用于本地开发。Compose 模式可以通过 `ZONGSOFT_REDIS_PASSWORD`、`ZONGSOFT_MYSQL_PASSWORD`、`ZONGSOFT_MYSQL_ROOT_PASSWORD`、`ZONGSOFT_POSTGRES_PASSWORD`、`ZONGSOFT_CLICKHOUSE_PASSWORD`、`ZONGSOFT_TDENGINE_ROOT_PASSWORD`、`ZONGSOFT_RUSTFS_ACCESS_KEY` 和 `ZONGSOFT_RUSTFS_SECRET_KEY` 环境变量覆盖默认值。
安装升迁包时，应确保 MySQL root 密码与 `.env` 中的 `[mysql] root_password` 一致。
