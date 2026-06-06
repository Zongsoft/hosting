# Web 宿主 Linux 发布验证工作流

## 目标

完成 `web/default` 宿主的 Linux 安装包发布验证：通过宿主脚本编译、部署、打包，将安装包安装到目标 Linux 的 `/opt`，并确认 systemd 服务、HTTP 端口和 Nginx 代理可用。

本工作流只适用于 `web/default`。宿主项目不承载业务代码，业务问题优先从插件、配置或外部服务定位。

## 硬性要求

- 必须执行 `web/default/deploy.cmd` 完成编译、部署和打包。
- 不允许自行拆出或重写 `dotnet cake`、`dotnet deploy`、`dotnet-pack` 命令来绕过 `deploy.cmd`。
- 不允许手写 `.service` 文件绕过打包器；systemd 服务文件必须由 `dotnet-pack` 根据脚本参数生成。
- 如果 `deploy.cmd` 在捕获式 shell 中无法有效运行，应切换真实 Windows 控制台，或报告环境阻塞；不要改走底层命令。
- 不要为了通过验证而向宿主项目添加临时业务逻辑。

## 执行前确认

确认或从上下文取得以下参数：

- `scheme`，默认通常为 `default`。
- `environment`，通常为 `development`、`test` 或 `production`。
- `debug`，通常正式 Linux 发布为 `off`；如用户说“默认”，按脚本默认输入。
- `platform`，Linux 发布必须输入 `linux`。
- `architecture`，通常为 `x64` 或 `arm64`。
- `framework`，例如 `net10.0`。
- 安装包格式：`.deb`、`.rpm` 或 `.tar.gz`，分别在脚本中输入 `deb`、`rpm`、`tar`。
- `version`，不能为空。
- `edition`，可为空。
- 目标 Linux：本机 WSL 发行版或远程主机信息。
- 验证入口：直连 `8069`，以及是否验证 Nginx `8080`/`80` 或域名入口。

## 执行流程

1. 进入 `<repo-root>\web\default`。
2. 执行 `.\deploy.cmd`，按已确认参数回答脚本提示。
3. 脚本成功后，按时间、版本、架构和格式定位新安装包。
4. 将安装包复制到目标 Linux 的 `/opt`。
5. 按包格式安装：
	- Debian/Ubuntu：`apt install -y /opt/<package>.deb`
	- RPM 系：`dnf install -y /opt/<package>.rpm`，必要时用 `yum` 或 `rpm`
	- `tar`/`tar.gz`：解压到约定目录后按包内安装脚本或说明注册服务
6. 验证 systemd 服务、HTTP 端口、Nginx 和日志。

如果在 WSL 中自动化安装，优先用 `wsl -d <distro> -u root -- bash -lc "<command>"` 避免 `sudo` 密码交互。

## 验证清单

- 安装包已位于 `/opt/<package>`。
- `dpkg -s zongsoft.web` 或等效 rpm 查询显示安装成功。
- `systemctl is-active zongsoft.web` 输出 `active`，或已记录实际服务名和状态。
- `ss -lntp` 显示 Web 服务监听 `8069`。
- `curl -i --max-time 10 http://127.0.0.1:8069/` 有 HTTP 响应。
- 如果安装了 Nginx，`nginx -t` 通过。
- `curl -i --max-time 10 http://127.0.0.1:8080/` 有 HTTP 响应。
- 如需验证域名入口，使用 `Host` 头验证 `80` 端口。
- `journalctl -u zongsoft.web -n 200 --no-pager` 中没有阻断启动的错误。

## 故障分流

- 编译失败：记录 `deploy.cmd` 中构建阶段的首个有效错误，优先检查 SDK、目标框架、框架源码和 NuGet 包。
- 部署失败：检查 `.deploy`、`../../.deploy/<scheme>/`、插件来源和目标路径。
- 打包失败：检查格式、版本、平台架构、Nginx 文件和 `dotnet-pack` 输出。
- 安装失败：检查包格式是否匹配发行版，以及 `apt`、`dpkg`、`dnf`、`yum`、`rpm` 输出。
- 服务启动失败：先看 `systemctl status` 和 `journalctl`，再判断是配置、插件、端口占用、基础服务还是打包器生成的 service 问题。
- 如果 `.service` 入口明显错误，例如启动了依赖库 `Zongsoft.Web.dll` 而不是宿主入口，应分析 `/Zongsoft/tools/packager` 的 systemd 生成逻辑并向用户报告，不要修改宿主脚本或手写 `.service` 绕过。
- 如果出现 `Could not load type 'Zongsoft.Components.Version'`，通常是 `plugins/` 中残留旧插件；删除 `web/default/plugins` 后重新执行 `deploy.cmd`。
- 如果同版本 deb 重装导致 `/opt/zongsoft/web` 丢失，不要用 `apt install --reinstall` 验证同版本包；先卸载 `zongsoft.web`，再安装 `/opt/<package>.deb`。
- 如果 Nginx 失败，先确认直连 `8069`，再检查 `/etc/nginx/conf.d/zongsoft.web.conf`、`nginx -t`、端口占用和代理目标。
- 如果日志显示数据库、Redis、对象存储等外部依赖不可用，如实记录依赖缺失，不要用宿主临时代码绕过。

## 验收标准

本轮通过需要同时满足：

- `deploy.cmd` 完成编译、部署和打包。
- 已记录安装包路径、文件名、版本、格式、架构和目标系统。
- 安装包已安装到目标 Linux。
- systemd 服务处于 `active`，或服务状态符合用户指定预期。
- `8069` 有 HTTP 响应。
- 若目标安装了 Nginx，Nginx 配置和代理入口验证通过。
- 最新日志无阻断启动错误。

## 回报格式

```text
web/default Linux 发布验证：
- 参数：scheme=<...>, environment=<...>, platform=linux, architecture=<...>, framework=<...>, format=<...>, version=<...>, debug=<...>
- 安装包：<path>
- 目标系统：<distro/host>
- 发布位置：/opt/<package>
- 服务：<service-name> => <active/failed/other>
- HTTP：8069 => <响应摘要>
- Nginx：<通过/未安装/失败原因>
- 日志：<关键警告或错误>
- 结论：<通过/未通过>
```
