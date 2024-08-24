## 部署

宿主程序只负责初始化运行时环境，作为插件的承载容器其自身并不含有具体的功能实现，我们通过将需要的插件及其相关附属(配置、证书)文件放置在 `plugins` 目录下的相应子目录中，这个行为即为部署。

运行 `deploy.cmd` _(**W**indows)_ 或 `deploy.sh` _(**L**inux/**U**nix)_ 脚本以执行由部署文件 _(`*.deploy`)_ 所定义的部署内容。

> 提示：部署脚本依赖 **Z**ongsoft.**T**ools.**D**eployer 工具进行部署操作，有关该工具的使用说明，请参考其开源项目的相关文档：
> - 英文：[https://github.com/Zongsoft/Zongsoft.Tools.Deployer/blob/master/README.md](https://github.com/Zongsoft/Zongsoft.Tools.Deployer/blob/master/README.md)
> - 中文：[https://github.com/Zongsoft/Zongsoft.Tools.Deployer/blob/master/README-zh_CN.md](https://github.com/Zongsoft/Zongsoft.Tools.Deployer/blob/master/README-zh_CN.md)

### 部署文件

通常配置文件与特定的 **产品**、**项目**、**部署平台** _（如：阿里云·Aliyun、微软·Azure、亚马逊·AWS）_ 及 **环境** _（如：开发、测试、生产）_ 相关，所以应该将这些特定相关性的文件单独存放在 `/hosting/.deploy` 目录下，以便于统一管理与跟踪维护。

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

- `certificates` 证书文件目录
	> 注：部署平台无关的证书文件。

- `{scheme}` 部署方案
	- `certificates` 证书文件目录
		> 注：与部署方案有关联的证书文件。
	- `options` 配置文件目录

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

> 有关 **Z**ongsoft.**T**ools.**D**eployer 部署工具的更多内部原理与实现，请访问该项目的开源网址：[https://github.com/Zongsoft/Zongsoft.Tools.Deployer](https://github.com/Zongsoft/Zongsoft.Tools.Deployer)
