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

如果在 WSL 中自动化安装，优先用 `wsl -d <distro> -u root -- bash -lc "<command>"` 避免 `sudo` 密码交互。PowerShell 调用 `bash -lc` 时，若命令中包含 Bash 变量，必须转义 `$` 或改用直接路径；安装包复制和安装这种短命令优先直接写 `/opt/<package>.deb`，避免 `$pkg` 被 PowerShell 提前展开为空。

### 自动化执行提示

- `deploy.cmd` 必须在真实 Windows 控制台中运行。`dotnet-deploy`、`dotnet-pack` 使用的终端库在 stdin/stdout 被捕获或重定向时可能抛出 `ConsoleTerminal`/`句柄无效` 异常。
- 如果当前文件是 LF 换行，捕获式 `cmd` 可能在 ESC 初始化行报 `& was unexpected at this time.`；不要改脚本绕过，将该脚本转换为 CRLF 换行格式后再执行。
- 不要一次性管道输入全部答案：前半段的 `dotnet cake` 或 `dotnet deploy` 可能消费后续输入，导致脚本停在安装包格式提示。自动化时先输入前 6 个参数，等 `dotnet` 子进程结束并进入打包提示后，再输入 `format`、`version`、`edition`。
- 可用可见 `cmd.exe` 窗口配合 `WScript.Shell.SendKeys` 分阶段输入；不要把 `dotnet-pack` 的 stdout/stderr 重定向到日志文件。
- `web/default/deploy.cmd` 当前用 `--name:Zongsoft.Hosting.Web`、`--title:Zongsoft.Web`、`--daemon:zongsoft.web` 打包：Debian 包名为 `zongsoft.web`，systemd 服务仍为 `zongsoft.web.service`。
- `dotnet-pack` 生成 service 时按 `--name` 定位宿主 DLL；如果改回 `--name:Zongsoft.Web`，会生成 `ExecStart=dotnet /opt/zongsoft/web/Zongsoft.Web.dll ...`，这是类库入口，会启动失败。
- 对 `.deb` 验证优先先用 `dpkg-deb -I <package>.deb` 确认实际 `Package` 名称。当前 `web/default/deploy.cmd` 生成的 Debian 包名是 `zongsoft.web`；干净安装时先 `apt remove -y zongsoft.hosting.web zongsoft.web`，必要时 `dpkg --purge zongsoft.hosting.web zongsoft.web` 清理旧包残留，再 `apt install -y /opt/<package>.deb`。不要用同版本重装或直接升级路径判断包是否可用，因为旧包脚本可能在升级过程中删除 `/opt/zongsoft/web`。
- 默认 Nginx 配置中 `8080` 的 `server_name` 是 `_`，`80` 的域名入口是 `api.zongsoft.com`；验证 `80` 时使用 `curl -H "Host: api.zongsoft.com" http://127.0.0.1/`。

## 验证清单

- 安装包已位于 `/opt/<package>`。
- `dpkg -s <实际包名>` 或等效 rpm 查询显示安装成功；`.deb` 的实际包名以 `dpkg-deb -I <package>.deb` 输出的 `Package` 字段为准。
- `systemctl is-active zongsoft.web` 输出 `active`，或已记录实际服务名和状态。
- `ss -lntp` 显示 Web 服务监听 `8069`。
- `curl -i --max-time 10 http://127.0.0.1:8069/` 有 HTTP 响应。
- 如果安装了 Nginx，`nginx -t` 通过。
- `curl -i --max-time 10 http://127.0.0.1:8080/` 有 HTTP 响应。
- 如需验证域名入口，使用 `Host: api.zongsoft.com` 验证 `80` 端口，除非当前 scheme 的 Nginx 配置另有 `server_name`。
- `journalctl -u zongsoft.web --since "<本次成功启动时间>" --no-pager` 中没有阻断启动的错误。
- 如果 `web/default/wwwroot` 为空，打包后可能没有 `/opt/zongsoft/web/wwwroot`，日志中的 `The WebRootPath was not found` 属于静态文件不可用 warning，不阻断本工作流通过。

## 故障分流

- 编译失败：记录 `deploy.cmd` 中构建阶段的首个有效错误，优先检查 SDK、目标框架、框架源码和 NuGet 包。
- 部署失败：检查 `.deploy`、`../../.deploy/<scheme>/`、插件来源和目标路径。
- 打包失败：检查格式、版本、平台架构、Nginx 文件和 `dotnet-pack` 输出。
- 安装失败：检查包格式是否匹配发行版，以及 `apt`、`dpkg`、`dnf`、`yum`、`rpm` 输出。
- 服务启动失败：先看 `systemctl status` 和 `journalctl`，再判断是配置、插件、端口占用、基础服务还是打包器生成的 service 问题。
- 如果 `.service` 入口明显错误，例如启动了依赖库 `Zongsoft.Web.dll` 而不是宿主入口，应分析 `/Zongsoft/tools/packager` 的 systemd 生成逻辑。当前已知修正方式是保持 `--daemon:zongsoft.web`，并用实际宿主程序集名 `--name:Zongsoft.Hosting.Web` 让打包器生成正确入口；不要手写 `.service` 绕过。
- 如果出现 `Could not load type 'Zongsoft.Components.Version'`，通常是 `plugins/` 中残留旧插件；删除 `web/default/plugins` 后重新执行 `deploy.cmd`。
- 如果 deb 重装或升级导致 `/opt/zongsoft/web` 丢失，不要用 `apt install --reinstall` 或升级路径继续验证；先卸载相关包并清理旧包残留，再安装 `/opt/<package>.deb`。
- 如果 Nginx 失败，先确认直连 `8069`，再检查 `/etc/nginx/conf.d/zongsoft.web.conf`、`nginx -t`、端口占用和代理目标。
- 如果日志仅包含 `The WebRootPath was not found`，且源目录 `web/default/wwwroot` 为空，可记录为非阻断 warning；不要为通过验证而添加占位静态文件。
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
