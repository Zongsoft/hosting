## 概述

本目录遵循 [../../AGENTS.md](../../AGENTS.md) 中的通用约定。

这是一个基于 Zongsoft 插件框架的插件式应用 ASP.NET _(Web API)_ 程序宿主项目。

## 测试

在 [../.http](../.http/) 目录中包含的 `*.http` 文件是相关资源的 Web API 的 HTTP 接口调用请求定义。

> 提示：`*.http` 文件是供 [HttpYac](https://httpyac.github.io)、[REST Client](https://marketplace.visualstudio.com/items?itemName=humao.rest-client) 等工具对 Web API 接口进行调测的文件。

### 使用方法

需要身份验证的 API 接口，通常通过 `Authorization` 头来传递身份凭证，身份凭证来自于就近的 `.env` 文件中的 `credentialId` 字段(变量)值。

如果凭证已过期或未定义，则需要先使用 `/Zongsoft/framework/Zongsoft.Security/docs/http/authentication.http` 中的 `Signin` 接口进行登录，然后将登录成功后的响应中的凭证编号保存到 `.env` 文件中的 `credentialId` 字段。
> 提示：在调试环境中可以尝试以 `Administrator` 账号（密码为空）进行登录；如果不行再来询问。

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
