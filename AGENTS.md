## 硬性要求

所有 `.cmd` 文件必须采用 CRLF 换行。
如果发现 `AGENTS.md` 或 `README*.md` 文档内容与实际功能特性有出入，则同步最新的代码功能特性到文档。

## 通用约定

本文件适用于 `hosting` 目录下的各宿主项目。更具体的子目录说明以就近的 `AGENTS.md` 为准。

- 保持已有文件的换行符，新文件使用 CRLF 换行格式；代码文件采用 Tab 缩进。
- `README.md` 为英文文档，`README.zh-Hans.md` 为简体中文文档；修改用户文档时应同步维护两种语言的结构和技术内容。
- 宿主项目本身不应包含业务代码，业务能力应由 `plugins/` 目录下的插件提供。
- 修改宿主项目时，优先关注 `Program.cs`、`appsettings.json`、`*.csproj`、`.deploy`、部署脚本和相关配置文件。

## 操作边界

- 未经明确要求，不运行 `deploy.cmd`、`pack.cmd`、`install.cmd`、`uninstall.cmd`、`upgrade.pack.cmd`、`upgrade.publish.cmd`、`zongsoft.pod(start).cmd`、`zongsoft.pod(stop).cmd`、`zongsoft.compose(start).cmd`、`zongsoft.compose(stop).cmd`。
- 这些脚本通常会交互式询问参数，并可能复制文件、启动或停止容器、生成安装包、发布升级包。确需执行前，先阅读脚本并说明影响。
- 如果需要业务行为，应先查找插件、配置、外部业务代码或 Zongsoft 框架代码，不要直接把业务逻辑加入宿主项目。

## AI 工作流文档

`.ai/` 目录存放面向特定任务的详细工作流。开始相关任务时应按需读取对应文档，不要将其中仅适用于特定宿主或平台的要求扩展到整个仓库：

- [`.ai/daemon.linux.md`](.ai/daemon.linux.md)：`daemon` 宿主的 Linux 编译、部署、打包、安装及服务验证工作流。
- [`.ai/web.linux.md`](.ai/web.linux.md)：`web/default` 宿主的 Linux 编译、部署、打包、安装、HTTP 及 Nginx 验证工作流。

使用这些工作流时遵循以下规则：

- 以目标目录就近的 `AGENTS.md` 为准；`daemon/AGENTS.md` 和 `web/default/AGENTS.md` 已分别关联对应工作流。
- `.ai/` 文档用于补充具体执行步骤，不替代本文件的通用约定、操作边界和验证要求。
- 引用工作流不代表获得运行部署、安装或容器启停脚本的授权；仍需满足用户请求及“操作边界”的要求。
- 新增、重命名或删除 `.ai/` 工作流时，应同步更新本索引和相关子目录的 `AGENTS.md`。

## 验证

- 只修改文档时，检查差异内容和换行符即可。
- 检查 Compose 配置时，可以运行不创建容器的 `podman compose --file zongsoft.compose.yaml --project-name zongsoft config`；未经明确要求，不运行 Compose 启停脚本或实际创建服务。
- 检查 K8s Pod YAML 时以静态审查为主；`podman kube play` 会创建或替换 Pod，未经明确要求不得作为验证命令执行。
- 除非任务明确涉及启动、配置、部署或承载行为，通常无需修改宿主代码，因为宿主程序不含具体业务或功能代码 _(可以将它理解成程序的启动器)_。
- 需要通过宿主程序验证特定插件改动时，通常应先停止宿主程序，然后手动将插件部署到对应的插件目录，再重启宿主程序进行验证。
- 修改 Web API 相关内容后，可参考 `web/.http` 目录下的请求定义，或将其转换为 `curl` 等方式进行接口验证。
- 如果验证失败是因为插件、容器或 `/Zongsoft/framework`、`/Zongsoft/tools` 等外部依赖不可用，应在结果中说明，不要用临时业务代码绕过。

## 原理

这些宿主项目都是基于 [Zongsoft](https://github.com/Zongsoft/framework) [插件框架](https://github.com/Zongsoft/framework/tree/main/Zongsoft.Plugins) 的插件式应用宿主程序。

插件式应用的宿主程序本身不含任何业务代码，它通过插件框架加载 `plugins/` 目录下的所有插件文件 _(`*.plugin`)_ 来构建插件式应用的运行环境。

## 部署

部署就是将需要的插件拷贝到宿主程序插件目录中的相应位置。插件通常包括但不限于：

- 插件文件 `*.plugin` _(必须)_
- 配置文件 `*.option` _(可选)_
- 动态库文件 `*.dll` _(必须)_
- 调试符文件 `*.pdb` _(可选)_
- 数据映射文件 `*.mapping` _(可选)_
- 资源附属目录 `zh-Hans`, `zh-CN` _(可选)_

### 部署工具

通过 [`dotnet-deploy`](https://github.com/Zongsoft/tools/tree/main/deployer) 部署工具将需要的插件拷贝到宿主程序的 `plugins` 目录下特定位置。

部署工具通过 `.deploy` 文件的指引进行文件复制等操作，更详细的内容参考 `dotnet-deploy` 工具的相关文档和代码。

`daemon/deploy.cmd`、`terminal/deploy.cmd` 和 `web/default/deploy.cmd` 是本地 Debug 快捷入口：调用根目录 `deploy.cmd <source> --local-debug`，固定源目录为自身宿主，跳过调试模式、平台、架构和框架提示，使用 on、windows、x64 及现有框架默认值；方案、环境和网络仍按原有提示和默认值输入。快捷入口使用 `--overwrite:alway` 始终覆盖，普通根目录部署保持 `newest`。

hosting 根目录的 `deploy.cmd`、`pack.cmd`、`containerize.cmd` 和 `migrate.cmd` 分别调用同名 `.ps1` 脚本，各自负责对应工具的流程与参数。四个 PowerShell 入口点加载 `.shared.ps1`，共用交互、菜单、宿主发现、工具执行和错误处理；共享脚本不分发工具操作，加载时不启动任何工具流程。部署和打包扫描调用时当前目录及子目录中的宿主项目，以分层方向键菜单选择源目录；父目录只显示分组，不可选择，只有宿主叶子项带编号。`deploy.cmd` 进入所选宿主运行 Cake，再用 `--source`/`--output` 调用部署器；只负责构建和部署，成功后返回 0。安装包由根目录 `pack.cmd` 独立制作。

### 部署变量与模板

- 工具只加载 source 直属 `.env`（migrator 为工作目录）。宿主先导入 `../.env`，Web 站点经 `web/.env` 导入 hosting 根配置，再通过 `#@import ../.deploy/${scheme}/.env`（Web 多一级 `../`）选择方案。`.deploy/.env` 也显式导入 hosting 根配置，为方案的环境、网络指令提供默认值；方案再导入自己的变量文件，工具不固化额外优先级或目录组合。
- `.deploy` 文件通过 `${scheme}` 选择独有资产，公共配置结构在 `.deploy/.shared/*.template`，用 template 解析器生成最终文件；`.env` 不部署。
- 一次部署只选一个环境及一种网络；网络独立于 debug。公共模板的路径并不决定变量作用域。
- 根脚本的 source 自动发现和显式相对路径基于调用时的当前目录；deployer/packager 的本地相对输入输出基于选中的 source。`.deploy` 和 import 内部引用仍基于声明文件。
- Web 打包身份来自 `web/.env` 的 application 命名空间，入口必须保持 Zongsoft.Hosting.Web，标题 Zongsoft.Web，服务 zongsoft.web；脚本用显式模板参数传给 packager。

### 手工部署

在调试期间，往往只是修改编译了某个插件，如果通过 `dotnet-deploy` 部署工具对所有插件都进行一遍部署会很耗时，且可能影响到手工部署的内容，因此根据需要手动复制某个或某些插件到其部署位置的方式即为手工部署。

## 容器化

宿主程序及其插件可能依赖数据库、分布式缓存、分布式配置和分布式文件系统。`hosting` 根目录提供两套并列的 Podman 容器化方案，维护时必须保留两种模式，不能以其中一种替换或删除另一种。

`containerize.cmd` 的完整制作/plan 先逐行输入基础服务，再从 hosting 根目录自动发现的分层菜单中多选宿主。Space 勾选、Enter 确认；重定向时用逗号分隔的编号或完整相对路径。允许仅服务或仅宿主，但不能两者均空。make/run 保留文件选择与 Esc 返回；直接参数原样交给工具，制作追加固定 source/output，run 不追加。`migrate.cmd` 只输入升迁文件/模式，平台与架构共用菜单，不增加宿主选择。四个脚本的公共交互代码集中在 `.shared.ps1`；重定向不暂停，输入耗尽即取消。

### K8s Pod 模式

- 定义文件：`zongsoft.pod-*.yaml`
- 启动脚本：`zongsoft.pod(start).cmd`
- 停止脚本：`zongsoft.pod(stop).cmd`
- 管理命令：`podman kube play`、`podman kube down`
- 生命周期：`kube down` 删除 Pod 和容器，容器可写层数据不保留。
- 特殊限制：MySQL 与 PostgreSQL 使用相同的 `zongsoft.data` Pod 名，该模式下不应同时运行。

### Podman + Docker Compose 模式

- 定义文件：`zongsoft.compose.yaml`
- 启动脚本：`zongsoft.compose(start).cmd`
- 停止脚本：`zongsoft.compose(stop).cmd`
- 管理命令：`podman compose`
- 生命周期：停止脚本默认保留容器数据；`--clean` 删除容器及匿名卷。
- 服务寻址：容器间优先使用 `host`、`etcd`、`redis`、`mysql`、`postgres`、`rustfs` 等 Compose 服务名。

### 共同约定

- 两种模式均包含开发宿主、Etcd、Redis、MySQL、PostgreSQL 和 RustFS。
- 两种模式共享 `zongsoft-net` 网络、Windows 宿主端口和部分网络别名，不要同时用两种模式启动同一个服务。
- Windows 访问容器使用 `localhost` 及映射端口；容器访问 Windows 使用 `host.containers.internal`。
- 不要依赖或记录容器 IP；Pod、Compose 服务名及网络别名才是稳定连接地址。
- `host` 容器的 `/Zongsoft`、数据库初始化 SQL 和 RustFS 数据均来自宿主机绑定路径，修改路径时要同步评估两种模式。
- 修改某个服务的镜像、端口、环境变量、挂载或初始化脚本时，应判断另一种模式是否也需要同步；如果刻意只修改一种模式，应在结果中说明差异。
- 两种模式地位相同；不得以维护或重构其中一种模式为由删除、覆盖或降级另一种模式的文件、脚本及文档。
- README 的容器化章节必须分别保留两种模式的前置条件、启停方式、网络地址、数据生命周期和常用命令。

如果本机调试时无法连接 Redis、数据库等服务，应先确认选择的模式、目标服务状态、`zongsoft-net` 网络、宿主端口和 Podman machine 状态，不要通过向宿主项目添加临时业务代码绕过基础设施问题。

## 安装与升级

`pack.cmd` 是制作安装包的脚本，其内部通过 `dotnet-pack` 工具制作相应格式的安装包，如 `.deb`, `.rpm`, `tar.gz` 格式。

> 如果是在独立的 Linux 环境中测试宿主程序，最好通过该脚本制作相应格式的安装包进行测试验证。

根目录 `pack.cmd` 从自动发现的宿主菜单中选择源目录，默认 tar、Release、x64 和 Linux，只打包已有输出。打包时选择与部署一致的源目录、编译配置、架构、方案、环境、网络及框架覆盖。输出默认是所选 source 下的 `.packages/`，也可另选。环境直接接受输入；留空保留进程 Environment，未定义时用 development。框架覆盖留空时，工具使用 `.env`，Cake 使用 build.cake 默认值，须保持一致；分别在 deploy.cmd 与 pack.cmd 中输入相同的显式框架覆盖。构建、部署或打包失败显示阶段和原始退出码。交互模式下成功和失败均等待按键，菜单 Esc 取消返回 2；重定向时采用编号菜单、纯文本输出且不暂停，输入耗尽即取消。所有出口保留调用者的目录与环境。

根目录 `migrate.cmd` 调用独立 `dotnet-migrate` 制作配套升迁归档和启动脚本，输出在 `.migration/`；默认输入是 `.deploy/${scheme}/migration/${version}/*.migration`。宿主打包脚本通过 `--migration` 传入升迁名称或路径，仅查找已有产物，不制作升迁；必须匹配最终 Edition、版本与 RID。归档内部不套 `.migration`，安装包仅把配套文件收纳到安装根 `.migration/`，执行时解压到独立临时目录。详细参数和版本回写见 [README](README.zh-Hans.md#安装包与升迁包)。

升级包用于程序运行中的版本发现、下载、解压、部署和重启等自动升级流程。
`upgrade.pack.cmd` 用于制作升级包，`upgrade.publish.cmd` 用于发布升级包；
详细机制参考 [Zongsoft 自动升级框架](https://github.com/Zongsoft/framework/tree/main/upgrading) 及其相关代码和工具。

## 参考

- Zongsoft 开发框架
	> - 源码仓库：https://github.com/Zongsoft/framework
	> - 本机目录：`/Zongsoft/framework`

- Zongsoft 开发框架·核心库
	> - 源码仓库：https://github.com/Zongsoft/framework/tree/main/Zongsoft.Core
	> - 本机目录：`/Zongsoft/framework/Zongsoft.Core`

- Zongsoft 数据引擎
	> - 源码仓库：https://github.com/Zongsoft/framework/tree/main/Zongsoft.Data
	> - 本机目录：`/Zongsoft/framework/Zongsoft.Data`

- Zongsoft 插件框架
	> - 源码仓库：https://github.com/Zongsoft/framework/tree/main/Zongsoft.Plugins
	> - 本机目录：`/Zongsoft/framework/Zongsoft.Plugins`

- Zongsoft 部署工具
	> - 命令名称：`dotnet-deploy`
	> - 源码仓库：https://github.com/Zongsoft/tools/tree/main/deployer
	> - 本机目录：`/Zongsoft/tools/deployer`

- Zongsoft 打包工具 _(安装包制作)_
	> - 命令名称：`dotnet-pack`
	> - 源码仓库：https://github.com/Zongsoft/tools/tree/main/packager
	> - 本机目录：`/Zongsoft/tools/packager`
