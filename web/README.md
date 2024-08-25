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

## 服务

### REST Client

安装 **V**isual **S**tudio **C**ode 的 [REST Client](https://marketplace.visualstudio.com/items?itemName=humao.rest-client) 插件，并在 **VS** **C**ode 的配置文件中添加该插件的相关配置：

```json
{
	"rest-client.requestNameAsResponseTabTitle": true,
	"rest-client.defaultHeaders": {
		"X-Json-Behaviors": "casing:camel;ignores:null,empty",
		"User-Agent": "vscode-restclient"
	},
	"rest-client.environmentVariables": {
		"$shared": {
			"scenario": "api"
		},
		"local": {
			"host": "127.0.0.1",
			"port": "8069",
			"url": "{{host}}:{{port}}"
		},

		"production.a": {
			"host": "api.a.zongsoft.com",
			"port": "80",
			"url": "{{host}}:{{port}}"
		},
		"production.b": {
			"host": "api.b.zongsoft.com",
			"port": "80",
			"url": "{{host}}:{{port}}"
		},
		"production.c": {
			"host": "api.c.zongsoft.com",
			"port": "80",
			"url": "{{host}}:{{port}}"
		},
		"production.iot": {
			"host": "api.iot.zongsoft.com",
			"port": "80",
			"url": "{{host}}:{{port}}"
		},
		"production.gateway": {
			"host": "api.gateway.zongsoft.com",
			"port": "80",
			"url": "{{host}}:{{port}}"
		},

		"development.a": {
			"host": "api.dev.a.zongsoft.com",
			"port": "80",
			"url": "{{host}}:{{port}}"
		},
		"development.b": {
			"host": "api.dev.b.zongsoft.com",
			"port": "80",
			"url": "{{host}}:{{port}}"
		},
		"development.c": {
			"host": "api.dev.c.zongsoft.com",
			"port": "80",
			"url": "{{host}}:{{port}}"
		},
		"development.iot": {
			"host": "api.dev.iot.zongsoft.com",
			"port": "80",
			"url": "{{host}}:{{port}}"
		},
		"development.gateway": {
			"host": "api.dev.gateway.zongsoft.com",
			"port": "80",
			"url": "{{host}}:{{port}}"
		},

		"test.a": {
			"host": "api.test.a.zongsoft.com",
			"port": "80",
			"url": "{{host}}:{{port}}"
		},
		"test.b": {
			"host": "api.test.b.zongsoft.com",
			"port": "80",
			"url": "{{host}}:{{port}}"
		},
		"test.c": {
			"host": "api.test.c.zongsoft.com",
			"port": "80",
			"url": "{{host}}:{{port}}"
		},
		"test.iot": {
			"host": "api.test.iot.zongsoft.com",
			"port": "80",
			"url": "{{host}}:{{port}}"
		},
		"test.gateway": {
			"host": "api.test.gateway.zongsoft.com",
			"port": "80",
			"url": "{{host}}:{{port}}"
		}
	}
}
```

> 🚨 注意：请根据实际情况调整上述配置中的相关域名、端口号等设置。

### 目录文件

在 `.http` 目录内存放相关 *REST Client* 的服务文件，其中 `application.http` 为应用相关的服务内容。

在 `.http/sites` 目录包含各服务站点目录，各站点服务目录中的 `.env` 文件即为 *REST Client* 的环境文件，其中定义了该站点的通用环境参数。

> 💡 提示：站点服务目录下按照应用模块构建相应子目录，并按照模块内的目标构建相应的 `*.http` 服务文件，以方便查找使用。

## 部署

有关部署相关信息请参考上级目录中的 [README](../README.md) 文件。

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
