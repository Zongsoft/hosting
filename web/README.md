## 调试

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
