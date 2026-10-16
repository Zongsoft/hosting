## 概述

本目录遵循 [../AGENTS.md](../AGENTS.md) 中的通用约定。

这是一个基于 Zongsoft 插件框架的插件式应用后台服务程序宿主项目。

优先将本宿主用于后台服务、守护进程、安装包、系统服务相关问题的分析和验证。

## 说明

- 本目录的 `deploy.cmd` 调用 hosting 根目录部署脚本，固定本宿主、Debug、Windows、x64 和现有框架默认值，仅询问方案、环境和网络，并以 `--overwrite:alway` 始终覆盖，用于本地调试部署。
- 宿主程序通过插件框架加载 `plugins/` 目录下的 _`*.plugin`_ 文件来构建运行环境。
- 如果需要部署、打包、升级包等背景说明，请参考 [../AGENTS.md](../AGENTS.md)。
- 需要执行 daemon 的 Linux 安装验证时，优先参考 [../.ai/daemon.linux.md](../.ai/daemon.linux.md)。
- 自动化执行可向根目录 `deploy.cmd daemon` 和 `pack.cmd daemon` 重定向输入；必须覆盖全部提示，空行采用默认值，菜单接受编号或列出的值，输入耗尽即取消。重定向模式输出纯文本且不暂停；交互模式使用方向键和 Enter。若工具报告控制台句柄无效，切换真实 Windows 控制台或报告环境阻塞，不要拆底层命令绕过脚本。
- 本机 WSL 验证如果 `sudo` 需要密码，可使用 `wsl -d <发行版> -u root -- bash -lc "<命令>"` 完成复制、安装和 systemd 状态检查。
