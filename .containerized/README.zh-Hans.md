# Collector 与 Prometheus 容器配置

[English](README.md) | [简体中文](README.zh-Hans.md)

这些文件由包含 otel、prometheus 的 Containerizer 容器包使用。`collector.yaml` 由 OpenTelemetry Collector 读取，`prometheus.yaml` 由 Prometheus 读取；它们不属于 daemon、terminal 的插件配置。

## 配置资产

| 文件 | 用途 |
| --- | --- |
| [otel.template](templates/otel.template) | 将 collector.yaml 只读挂载至 /etc/otelcol-contrib/config.yaml |
| [collector.yaml](templates/collector.yaml) | 接收 OTLP gRPC :4317，将指标暴露于 :9464/metrics |
| [prometheus.template](templates/prometheus.template) | 将 prometheus.yaml 只读挂载至 /etc/prometheus/prometheus.yml，持久化 /prometheus |
| [prometheus.yaml](templates/prometheus.yaml) | 抓取 otel:9464，保留导出器的 job/instance 标签 |

[.settings](.settings) 提供 tag、repository、template 和 settings 默认值，不会自动选择服务。其中 otel/prometheus 段落已关联上面的自定义模板；镜像 tag 和 Prometheus 存储设置继续在这里维护。

## 使用现有容器化工具

从 hosting 根目录运行 `containerize.cmd`，选择完整制作或 `plan`，在基础服务输入中填写 `otel`、`prometheus` 及其他所需服务，再从下一步菜单选择应用宿主。Containerizer 自动读取 `.containerized/.settings`，将自定义模板路径写入生成的 `.container`。

如需只规划这两个服务（不创建、启动容器）：

```powershell
dotnet containerize plan otel prometheus --name:zongsoft --distribution:debian@13 --architecture:x64 --source:. --output:.containerized
```

准备好应用安装包后，可在组件列表中增加 `daemon` 等宿主目录，将应用和基础服务放进同一份计划。生成的 `.containerized/zongsoft@<version>-x64.container` 随后可交给 `dotnet containerize make` 制作。

已保存或手写的清单不合并 `.settings`。旧计划需要重新生成，或在原有服务段落中补上以下条目，同时保留已确认的 tag 和 settings：

```ini
[otel]
template=.containerized/templates/otel.template

[prometheus]
template=.containerized/templates/prometheus.template
```

这些条目只指定模板，不替换段落中的其他配置。工具内置的同名模板没有引用本项目的自定义 YAML。

Containerizer 会检查模板的 `[configuration]` 文件路径，将文件复制进交付包的 `config/`，生成只读配置挂载。相对 YAML 路径以模板目录为基准，template 路径以最终 source 为基准；YAML 正文按原文复制，不会替换 `${...}`。

## 网络与宿主配置

```text
daemon / terminal --OTLP gRPC--> otel:4317
Prometheus       --HTTP scrape--> otel:9464/metrics
Web + Diagnostics.Web <--HTTP scrape-- Prometheus（按需另加目标）
```

- `container` 部署方案使 daemon、terminal 使用 `server=http://otel:4317;protocol=grpc`；应用和基础设施必须进入同一容器网络。将应用节与两个基础服务放在同一份容器清单最直接。
- 仅制作基础设施时，本机的 daemon、terminal 使用 `http://127.0.0.1:4317`。此模板把 4317 发布到宿主回环地址；从其它机器接入须另外配置发布地址。
- Collector 在容器内绑定 `0.0.0.0:4317` 和 `0.0.0.0:9464`。9464 供同网络的 Prometheus 使用，无需发布到宿主。模板只启用 gRPC，没有启用 4318 HTTP 接收。
- Prometheus UI 默认发布到 `127.0.0.1:9090`。`otel:9464` 是 Collector 的容器服务名，不能改成本容器的 localhost。
- Web 默认通过 Diagnostics.Web 直接暴露 9465；所有宿主共用通用诊断模板，Web 站点通过 `diagnostics.telemetry:enabled=false` 关闭重复的 OTLP 指标上报。需要监控 Web 时，在 prometheus.yaml 中增加实际可达的 Web 目标，例如同网络中的 `zongsoft.web:9465`，或经过反向代理的 `/metrics` 地址。未确定部署拓扑时不预置虚构目标。

本组模板只处理指标。宿主模板也只启用指标；追踪、日志需要另配接收管线及后端，Prometheus 不存储这两类信号。通用 Diagnostics 包仍保留追踪导出能力。

Collector 汇总后的 `up` 反映 Collector 抓取状态；不能用它代表每个应用存活。默认 `metric_expiration: 2m` 会清除停止上报的数据，应用级告警应结合预期服务清单、缺失指标或后续专用心跳。

## 与其它容器方式配合

仓库原有 `zongsoft.compose.yaml` 和 `zongsoft.pod-*.yaml` 两套方式继续保留。此目录配置只由选择上述自定义模板的 Containerizer 清单使用，不会自动加入旧 Compose/Pod 定义。手工使用 Docker/Podman Compose 时挂载到表中对应容器路径；Kubernetes 使用 ConfigMap 等方式提供同样的文件，并调整服务 DNS。容器镜像不包含本项目的 .NET 插件。
