## 概述

本目录遵循 [../../AGENTS.md](../../AGENTS.md) 中的通用约定。

这是一个基于 Zongsoft 插件框架的插件式应用 ASP.NET _(Web API)_ 程序宿主项目。

优先将本宿主用于 HTTP 接口、ASP.NET 管线、认证授权、站点配置和 Web API 调测相关问题。

## 发布

Linux 编译、部署、打包和安装验证优先参考 [../../.ai/web.linux.md](../../.ai/web.linux.md)。

打包 Web 宿主时应由 `dotnet-pack` 根据 `pack.cmd` 或 `deploy.cmd` 中的参数统一生成 systemd 服务文件。不要手写 `.service` 文件绕过；如果生成的服务入口有问题，应分析 `/Zongsoft/tools/packager` 的 systemd 生成逻辑并报告原因。

`dotnet-pack` 会用 `--name` 推断宿主 DLL。当前 Web 宿主入口是 `Zongsoft.Hosting.Web.dll`，因此 `deploy.cmd` 打包时应保持 `--name:Zongsoft.Hosting.Web`、`--title:Zongsoft.Web`、`--daemon:zongsoft.web` 的组合，并确认包内安装目录仍为 `/opt/zongsoft/web`；这样生成的 service 会启动 `/opt/zongsoft/web/Zongsoft.Hosting.Web.dll`，systemd 服务名仍是 `zongsoft.web.service`。Debian 包名以 `dpkg-deb -I <package>.deb` 的 `Package` 字段为准，当前脚本生成的是 `zongsoft.web`。不要将 `--name` 改回 `Zongsoft.Web`，否则生成的 service 会启动类库 `Zongsoft.Web.dll` 而不是宿主入口。

本宿主默认引用 `/Zongsoft/framework` 的 Release 输出。若插件加载时报 `Could not load file or assembly 'Zongsoft.Web, Version=...'`，先核对并构建对应框架库的 Release 输出，再重新执行 `deploy.cmd`；例如 `dotnet build D:\Zongsoft\framework\Zongsoft.Web\src\Zongsoft.Web.csproj -c Release -f net10.0`。

在 WSL 中验证 `.deb` 时优先干净安装：先用 `dpkg-deb -I` 确认实际包名，再卸载旧的 `zongsoft.hosting.web`/`zongsoft.web` 包并清理残留，最后安装 `/opt/<package>.deb`。PowerShell 调用 `wsl ... bash -lc` 时，短命令优先直接写包路径，或转义 Bash 变量中的 `$`，避免变量被 PowerShell 提前展开为空。同版本重装或直接升级可能触发旧包脚本删除 `/opt/zongsoft/web`，导致包数据库显示已安装但服务文件和应用文件不存在。

如果 `web/default/wwwroot` 为空，打包后的 `/opt/zongsoft/web/wwwroot` 可能不存在，服务日志中的 `The WebRootPath was not found` 是静态文件不可用 warning，不应作为 Linux 发布验证失败依据；不要为了消除该 warning 往宿主项目添加占位业务或静态文件。

## 测试

在 [../.http](../.http/) 目录中包含的 `*.http` 文件是相关资源的 Web API 的 HTTP 接口调用请求定义。

> 提示：`*.http` 文件是供 [HttpYac](https://httpyac.github.io)、[REST Client](https://marketplace.visualstudio.com/items?itemName=humao.rest-client) 等工具对 Web API 接口进行调测的文件。

### 使用方法

需要身份验证的 API 接口，通常通过 `Authorization` 头来传递身份凭证，身份凭证来自于就近的 `.env` 文件中的 `credentialId` 字段(变量)值。

如果凭证已过期或未定义，则需要先使用 `/Zongsoft/framework/Zongsoft.Security/docs/http/authentication.http` 中的 `Signin` 接口进行登录，然后将登录成功后的响应中的凭证编号保存到 `.env` 文件中的 `credentialId` 字段。
> 提示：在调试环境中可以尝试以 `Administrator` 账号（密码为空）进行登录；如果不行再来询问。

调试验证时可以读取并使用 `.env` 中的真实凭证值；但不要在回复中原样暴露，必要时仅脱敏展示。修改 `.env` 前应确认这是调试所需。

如果不方便通过 _HttpYac_、_REST Client_ 调用 `*.http` 文件中定义的接口，也可以通过类似于 `curl` 或自行构建脚本的方式调用 API 接口，因为 `*.http` 文件本质上就是对 HTTP 请求的简单包装模拟，所以很容易将它的定义转换成 `curl` 或其他工具、脚本的调用方式。

> - 如果缺少相应的 `.http` 文件，可根据需要添加相应的文件；
> - 如果 `.http` 文件内缺少相应的接口定义，可根据需要添加或完善相应的接口定义。

## 参考

- Zongsoft 开发框架·Web 扩展
	> - 源码仓库：https://github.com/Zongsoft/framework/tree/main/Zongsoft.Web
	> - 本机目录：`/Zongsoft/framework/Zongsoft.Web`

- Zongsoft 插件框架·Web 扩展
	> - 源码仓库：https://github.com/Zongsoft/framework/tree/main/Zongsoft.Plugins.Web
	> - 本机目录：`/Zongsoft/framework/Zongsoft.Plugins.Web`

- HttpYac 工具
	> 提供 `.http` 文件的 CLI 执行环境。
	> - 网址：https://httpyac.github.io
	> - 源码：https://github.com/anweber/httpyac

- REST Client for VSCode 插件
	> 提供 `.http` 文件的 VSCode 执行环境。
	> - 网址：https://marketplace.visualstudio.com/items?itemName=humao.rest-client

## 说明

- 宿主程序通过插件框架加载 `plugins/` 目录下的 _`*.plugin`_ 文件来构建运行环境。
- 如果需要部署、打包、升级包等背景说明，请参考 [../../AGENTS.md](../../AGENTS.md)。
