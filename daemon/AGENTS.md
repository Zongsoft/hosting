## 概述

本目录遵循 [../AGENTS.md](../AGENTS.md) 中的通用约定。

这是一个基于 Zongsoft 插件框架的插件式应用后台服务程序宿主项目。

优先将本宿主用于后台服务、守护进程、安装包、系统服务相关问题的分析和验证。

## 说明

- 宿主程序通过插件框架加载 `plugins/` 目录下的 _`*.plugin`_ 文件来构建运行环境。
- 如果需要部署、打包、升级包等背景说明，请参考 [../AGENTS.md](../AGENTS.md)。
- 需要执行 daemon 的 Linux 安装验证时，优先参考 [../.ai/daemon.linux.md](../.ai/daemon.linux.md)。
- 在自动化环境中不要用管道或输入重定向喂给 `deploy.cmd`；如遇 `dotnet-deploy` 或 `dotnet-pack` 抛出 `句柄无效`，切换真实 Windows 控制台运行 `deploy.cmd`，或报告环境阻塞，不要拆底层命令绕过脚本。
- 本机 WSL 验证如果 `sudo` 需要密码，可使用 `wsl -d <发行版> -u root -- bash -lc "<命令>"` 完成复制、安装和 systemd 状态检查。
