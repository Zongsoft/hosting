## 概述

本目录遵循 [../AGENTS.md](../AGENTS.md) 中的通用约定。

这是一个基于 Zongsoft 插件框架的插件式应用终端程序宿主项目。

> 它主要用于模拟后端服务程序。因为本终端程序支持命令行交互，相对 [daemon](../daemon/) 宿主程序而言，对人机调试更加方便友好。

优先将本宿主用于交互式调试、命令行复现和观察插件式应用的运行行为。

## 说明

- 宿主程序通过插件框架加载 `plugins/` 目录下的 _`*.plugin`_ 文件来构建运行环境。
- 如果需要部署、打包、升级包等背景说明，请参考 [../AGENTS.md](../AGENTS.md)。

## 升级验证

- 自动升级验证时，发布名称必须和运行时应用名一致；当前启动代码传入的应用名是 `zongsoft.terminal`，执行前应再用部署目录下的 `.version` 或 deployer 日志中的 `app.name` 复核。
- 执行 `dotnet cake` 或 `dotnet deploy` 后，重新确认 `plugins/zongsoft/upgrader` 和 `.deployer/Zongsoft.Upgrading.Deployer.exe` 是否仍存在，因为部署过程可能清理手工放入的升级组件。
- 打包运行中的部署目录时，排除 `logs/`，并确认 `.zip` 与 `.manifest` 都生成成功后再发布。
