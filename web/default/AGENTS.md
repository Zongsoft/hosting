## 概述

这是一个基于 [Zongsoft](https://github.com/Zongsoft/framework) [插件框架](https://github.com/Zongsoft/framework/tree/main/Zongsoft.Plugins) 的插件式应用的 ASP.NET _(Web API)_ 程序的宿主项目。

## 原理

插件式应用的宿主程序本身不含任何业务代码，它通过插件框架加载 `plugins/` 目录下的所有插件文件 _`*.plugin`_ 来构建插件式应用的运行环境。

## 部署

部署就是将需要的插件拷贝到宿主程序插件目录中的相应位置。插件通常包括但不限：

- 插件文件 `*.plugin` _(必须)_
- 配置文件 `*.option` _(可选)_
- 动态库文件 `*.dll` _(必须)_
- 调试符文件 `*.pdb` _(可选)_
- 数据映射文件 `*.mapping` _(可选)_
- 资源附属目录 `zh-Hans`, `zh-CN` _(可选)_

### 部署工具

通过 [`dotnet-deploy`](https://github.com/Zongsoft/tools/tree/main/deployer) 部署工具将需要的插件拷贝到宿主程序的 `plugins` 目录下特定位置。

部署工具通过 `.deploy` 文件的指引进行文件复制等操作，更详细的内容参考 `dotnet-deploy` 工具的相关文档和代码。

本项目中的 `deploy.cmd` 就是执行部署的脚本文件。注意：它的内部还包含了可选的制作安装包的命令：[`dotnet-pack`](https://github.com/Zongsoft/tools/tree/main/packager)。
> 提示：执行该脚本时，如果只部署不打包，则传入 `exit` 给其内部的打包命令。

### 手工部署

在调试期间，往往只是修改编译了某个插件，如果通过 `dotnet-deploy` 部署工具对所有插件都进行一遍部署会很耗时，且可能影响到手工部署的内容，因此根据需要手动复制某个或某些插件到其部署位置的方式即为手工部署。

## 容器化

由于应用程序的业务代码很可能依赖于数据库、分布式缓存、分布式文件系统等基础服务，因此在 `hosting` 根目录准备好了相关基础服务的 Podman 容器文件：

- Redis 缓存库：`zongsoft.pod-redis.yaml`
- MySQL 数据库：`zongsoft.pod-mysql.yaml`
- RustFS 分布式文件系统：`zongsoft.pod-rustfs.yaml`

为了方便加载和卸载这些基础服务，还提供了相关脚本：
> 这些脚本运行后需要人工输入启停的服务名，在自动化调用过程中需要注意这点。

- 启动脚本：`zongsoft.pod(start).cmd`
- 卸载脚本：`zongsoft.pod(stop).cmd`

提示：如果在本机环境中调试宿主程序，如果发现无法连接到 Redis、数据库等运行时错误，则可能是依赖的基础服务的容器尚未加载。

## 安装包

`pack.cmd` 是制作安装包的脚本，其内部通过 `dotnet-pack` 工具制作相应格式的安装包，如 `.deb`, `.rpm`, `tar.gz` 格式。

> 如果是在独立的 Linux 环境中测试宿主程序，最好通过该脚本制作相应格式的安装包进行测试验证。

## 升级包

升级包不同于安装包，升级包是指程序在运行中，发现有可升级的新版本，并执行一系列的发现、下载、解压、部署、重启程序等多步骤、协调运行等机制，详细内容参考 [Zongsoft 自动升级框架](https://github.com/Zongsoft/framework/tree/main/upgrading)及其相关文档、代码、工具等：

- 升级器：https://github.com/Zongsoft/framework/tree/main/upgrading/upgrader
	> 升级器提供了运行时自动发现可用的升级包、下载、解压、激活部署器等功能，它负责整个升级部署的前半截功能。

- 部署器：https://github.com/Zongsoft/framework/tree/main/upgrading/deployer
	> 部署器提供了执行部署、重启宿主程序等功能，它负责整个升级部署的后半截功能。

- 工具集：https://github.com/Zongsoft/framework/tree/main/upgrading/tool
	> 提供了打包、验证、发布等功能。

### 打包

`upgrade-pack.cmd` 是制作升级包的脚本，其内部通过 `dotnet-upgrade` 工具的 `pack` 命令来制作升级包。

### 发布

`upgrade-publish.cmd` 是发布升级包的脚本，其内部通过 `dotnet-upgrade` 工具的 `publish` 命令来发布制作好的升级包。

制作好的升级包通过该命令发布到特定的通道中，发布成功后，升级器才有可能发现发布的新版本升级包，然后通过 Zongsoft 自动升级框架去执行一系列的升级动作。

## 测试

在 [.http](../.http/) 目录中包含的 `*.http` 文件是相关资源的 Web API 的 HTTP 接口的调用请求定义。

> 提示：`*.http` 文件是供 [HttpYac](https://httpyac.github.io)、[REST Client](https://marketplace.visualstudio.com/items?itemName=humao.rest-client) 等工具对 Web API 接口进行调测的文件。

### 使用方法

需要身份验证的 API 接口，通常通过 `Authorization` 头来传递身份凭证，身份凭证来自于就近的 `.env` 文件中的 `credentialId` 字段(变量)值。

如果凭证已过期或未定义，则需要先使用 `/Zongsoft/framework/Zongsoft.Security/docs/http/authentication.http` 中的 `Signin` 接口进行登录，然后将登录成功后的响应中的凭证编号保存到 `.env` 文件中的 `credentialId` 字段。
> 提示：在调试环境中可以试下以 `Administrator` 账号（密码为空）进行登录；如果不行再来询问。

如果不方便通过 _HttpYac_、_REST Client_ 调用 `*.http` 文件中定义的接口，也可以通过类似于 `curl` 或自行构建脚本进行 API 接口调用，因为 `*.http` 文件本质就是对 HTTP 请求的简单包装模拟，所以很容易将它的定义转换成 `curl` 或其他工具、脚本的调用方式。

> - 如果缺少相应的 `.http` 文件，可根据需要添加相应的文件；
> - 如果 `.http` 文件内缺少相应的接口定义，可根据需要添加或完善相应的接口定义。

## 参考

- Zongsoft 开发框架
	> - 源码仓库：https://github.com/Zongsoft/framework
	> - 本机目录：`/Zongsoft/framework`

- Zongsoft 开发框架·核心库
	> - 源码仓库：https://github.com/Zongsoft/framework/tree/main/Zongsoft.Core
	> - 本机目录：`/Zongsoft/framework/Zongsoft.Core`

- Zongsoft 开发框架·Web 扩展
	> - 源码仓库：https://github.com/Zongsoft/framework/tree/main/Zongsoft.Web
	> - 本机目录：`/Zongsoft/framework/Zongsoft.Web`

- Zongsoft 数据引擎
	> - 源码仓库：https://github.com/Zongsoft/framework/tree/main/Zongsoft.Data
	> - 本机目录：`/Zongsoft/framework/Zongsoft.Data`

- Zongsoft 插件框架
	> - 源码仓库：https://github.com/Zongsoft/framework/tree/main/Zongsoft.Plugins
	> - 本机目录：`/Zongsoft/framework/Zongsoft.Plugins`

- Zongsoft 插件框架·Web 扩展
	> - 源码仓库：https://github.com/Zongsoft/framework/tree/main/Zongsoft.Plugins.Web
	> - 本机目录：`/Zongsoft/framework/Zongsoft.Plugins.Web`

- Zongsoft 部署工具
	> - 命令名称：`dotnet-deploy`
	> - 源码仓库：https://github.com/Zongsoft/tools/tree/main/deployer
	> - 本机目录：`/Zongsoft/tools/deployer`

- Zongsoft 打包工具 _(安装包制作)_
	> - 命令名称：`dotnet-pack`
	> - 源码仓库：https://github.com/Zongsoft/tools/tree/main/packager
	> - 本机目录：`/Zongsoft/tools/packager`

- HttpYac 工具
	> 提供 `.http` 文件的 CLI 执行环境。
	> - 网址：https://httpyac.github.io
	> - 源码：https://github.com/anweber/httpyac

- REST Client for VSCode 插件
	> 提供 `.http` 文件的 VSCode 执行环境。
	> - 网址：https://marketplace.visualstudio.com/items?itemName=humao.rest-client
