[English](README.md) | [简体中文](README.zh-Hans.md)

## 目录结构

通常 Web 宿主程序下分为不同的站点，譬如在 **SaaS** 应用中通常分为：
- 管理端 (`administration`)
	> 为 SaaS 平台方的 *人工* 站点。
- 商家端 (`business`)
	> 为 SaaS 商家用户的 *人工* 站点。
- 客户端 (`customer`)
	> 为 SaaS 终端用户的 *人工* 站点。
- 网关端 (`gateway`)
	> 为外部系统提供回调、互联互通等功能，为 _非人工_ 站点。
- 设备端 (`iot`)
	> 为物联网设备提供接入相关的功能，为 _非人工_ 站点。

> 本例只定义了 `default` 站点，可根据需要构建相应的站点目录，其内容与 `default` 站点基本一致，但需要调整 *编译脚本* 和 *部署脚本* 文件内 `site` 参数的值。

## 默认站点打包

`default/web.profile` 定义 HTTP 80 与 8080 的 IPv4/IPv6 入口，`server = ~` 使用打包时 `--listen:8069` 对应的应用地址。`deploy.cmd` 和 `pack.cmd` 使用 `--daemon:zongsoft.web --web:nginx` 生成 systemd 服务与 Nginx 配置，不再引用 `.deploy/default/systemd` 或 `.deploy/default/nginx`。

安装后的真实配置位于 `/opt/zongsoft/web/.web/nginx/zongsoft.web.conf`。默认激活会创建 `/etc/nginx/conf.d/zongsoft.web.conf` 符号链接、校验 Nginx 配置，并在 Nginx 已运行时重载；不会启动原先停止的 Nginx。制作容器镜像时设置 `HOSTER_WEB_ACTIVATION=0`（也接受 `false`，不区分大小写）可仅交付真实配置，镜像构建工具从安装根的 `.web/nginx/` 获取它。此开关只控制 Web 托管器；应用服务仍遵循 daemon 生命周期。

`--web` 不改变输入文件的收录规则；当前脚本显式选择载荷，没有选择 `web.profile`，因此包内只包含生成后的 Nginx 配置。需要交付原始 Profile 时可添加位置参数；排除时使用 `--exclude:*.profile`。

开发容器仅准备 systemd/Nginx 等运行环境；应用服务和托管器配置在安装应用包时交付。两种容器模式均不再链接源码中的预制服务或 Nginx 文件。

## 服务

### HttpYac

安装 **V**isual **S**tudio **C**ode 的 [HttpYac](https://marketplace.visualstudio.com/items?itemName=anweber.vscode-httpyac) 插件，并在 **VS** **C**ode 的 `settings.json` 配置文件中添加该插件的相关配置：

```json
{
	"httpyac.environmentPickMany": false,
	"httpyac.environmentUseSameForAllFiles": true,
	"httpyac.environmentShowStatusBarItem": true,
	"httpyac.environmentStoreSelectedOnStart": false,
	"httpyac.requestDefaultHeaders": {
		"X-Json-Behaviors": "casing:camel;ignores:null,empty",
		"User-Agent": "httpyac"
	},
	"httpyac.codelens": {
		"send": true,
		"clearHistory": true,
		"saveResponse": true,
		"sendSelected": true,
		"showResponse": true,
		"showResponseHeaders": true,
		"showVariables": true,
		"pickEnvironment": true,
		"resetEnvironment": true,
		"validateVariables": true
	},
	"httpyac.environmentVariables": {
		"$shared": {
			"scenario": "api"
		},
		"local": {
			"environmentName": "local",
			"host": "127.0.0.1",
			"port": "8069",
			"url": "{{host}}:{{port}}"
		},

		"production.a": {
			"environmentName": "production.a",
			"host": "api.a.zongsoft.com",
			"port": "80",
			"url": "{{host}}:{{port}}"
		},
		"production.b": {
			"environmentName": "production.b",
			"host": "api.b.zongsoft.com",
			"port": "80",
			"url": "{{host}}:{{port}}"
		},
		"production.c": {
			"environmentName": "production.c",
			"host": "api.c.zongsoft.com",
			"port": "80",
			"url": "{{host}}:{{port}}"
		},
		"production.iot": {
			"environmentName": "production.iot",
			"host": "api.iot.zongsoft.com",
			"port": "80",
			"url": "{{host}}:{{port}}"
		},
		"production.gateway": {
			"environmentName": "production.gateway",
			"host": "api.gateway.zongsoft.com",
			"port": "80",
			"url": "{{host}}:{{port}}"
		},

		"development.a": {
			"environmentName": "development.a",
			"host": "api.dev.a.zongsoft.com",
			"port": "80",
			"url": "{{host}}:{{port}}"
		},
		"development.b": {
			"environmentName": "development.b",
			"host": "api.dev.b.zongsoft.com",
			"port": "80",
			"url": "{{host}}:{{port}}"
		},
		"development.c": {
			"environmentName": "development.c",
			"host": "api.dev.c.zongsoft.com",
			"port": "80",
			"url": "{{host}}:{{port}}"
		},
		"development.iot": {
			"environmentName": "development.iot",
			"host": "api.dev.iot.zongsoft.com",
			"port": "80",
			"url": "{{host}}:{{port}}"
		},
		"development.gateway": {
			"environmentName": "development.gateway",
			"host": "api.dev.gateway.zongsoft.com",
			"port": "80",
			"url": "{{host}}:{{port}}"
		},

		"test.a": {
			"environmentName": "test.a",
			"host": "api.test.a.zongsoft.com",
			"port": "80",
			"url": "{{host}}:{{port}}"
		},
		"test.b": {
			"environmentName": "test.b",
			"host": "api.test.b.zongsoft.com",
			"port": "80",
			"url": "{{host}}:{{port}}"
		},
		"test.c": {
			"environmentName": "test.c",
			"host": "api.test.c.zongsoft.com",
			"port": "80",
			"url": "{{host}}:{{port}}"
		},
		"test.iot": {
			"environmentName": "test.iot",
			"host": "api.test.iot.zongsoft.com",
			"port": "80",
			"url": "{{host}}:{{port}}"
		},
		"test.gateway": {
			"environmentName": "test.gateway",
			"host": "api.test.gateway.zongsoft.com",
			"port": "80",
			"url": "{{host}}:{{port}}"
		}
	}
}
```

> 🚨 注意：请根据实际情况调整上述配置中的相关域名、端口号等设置。

### 目录文件

在 `.http` 目录内存放相关 *HttpYac* 请求文件，其中 `application.http` 为应用相关的服务内容，`authentication.http` 为身份认证相关的请求入口。

在 `.http/sites` 目录内按站点组织请求文件。各环境的通用参数统一配置在 **VS Code** `settings.json` 的 `httpyac.environmentVariables` 中；执行请求前可通过 HttpYac 状态栏选择目标环境。身份认证成功后，认证脚本会把凭证写回当前环境，因此每个环境都必须定义与环境键同名的 `environmentName`。

> 💡 提示：站点服务目录下按照应用模块构建相应子目录，并按照模块内的目标构建相应的 `*.http` 服务文件，以方便查找使用。

> 💡 更多语法和配置说明请参考 [HttpYac 官方文档](https://httpyac.github.io)。

## 部署

有关部署相关信息请参考上级目录中的 [README](../README.zh-Hans.md) 文件。

`default/deploy.cmd` 向 `dotnet deploy` 传入 `--prerelease:true`，因为 AI 插件引用的 SemanticKernel 连接器包含预发布包。该选项允许未固定版本的包请求选择预发布版本，显式固定的版本不受影响。

## 其他

### 站点绑定

如果在 **V**isual **S**tudio 使用 IIS Express 作为 Web 服务器，它默认只绑定了 `localhost` 的主机名，这就意味着无法通过IP或其他自定义域名进行访问，可通过如下操作添加其他绑定。

在 Web 宿主项目中的 `.vs` 目录中的 `config` 子目录中，有名为 `applicationhost.config` 配置文件，打开它后，找到如下节点：

```plain
system.applicationHost/sites/site[name=xxxx]/bindings
```

1. 在绑定集中添加一个对应IP或自定义域名的绑定节点，譬如：
```xml
<binding protocol="http" bindingInformation="*:8069:127.0.0.1" />
```

2. 以管理员方式运行“命令终端”，然后在终端执行器中执行下面命令：
> 注意：下面命令中的 `url` 参数值必须以 `/` 结尾，否则命令将执行失败。

```shell
netsh http add urlacl url=http://*:8069/ user=everyone
netsh http show urlacl
```

### 请求限制

IIS Express 服务器默认限制了HTTP的请求内容大小，这会导致在上传较大文件时请求被拒绝，通过如下方式可重置默认限制值。

在 Web 宿主项目中的 `.vs` 目录中的 `config` 子目录中，有名为 `applicationhost.config` 配置文件，打开它后，找到如下节点：

```plain
system.webServer/security/requestFiltering
```

在该节点下添加如下子节点，假定重新设置请求内容长度限制为：`500MB`
```xml
<requestLimits maxAllowedContentLength="524288000" />
```

然后修改 Web 宿主项目的 `Web.config` 文件中的如下配置节：
```xml
<system.web>
	<httpRuntime maxRequestLength="524288000" />
</system.web>
```

### 参考资料

- 《[netsh http 命令](https://learn.microsoft.com/zh-cn/windows-server/networking/technologies/netsh/netsh-http)》
- 《[处理 IIS Express 中的 URL 绑定失败](https://learn.microsoft.com/zh-cn/iis/extensions/using-iis-express/handling-url-binding-failures-in-iis-express)》
