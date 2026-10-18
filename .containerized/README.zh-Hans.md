# Collector 与 Prometheus 容器配置

[English](README.md) | [简体中文](README.zh-Hans.md)

这些文件由 Containerizer 制作基础设施容器包时使用。`collector.yaml` 由 OpenTelemetry Collector 读取，`prometheus.yaml` 由 Prometheus 读取；它们不属于 daemon、terminal 的插件配置。

## 配置资产

| 文件 | 用途 |
| --- | --- |
| [diagnostics.container](diagnostics.container) | 仅选择 otel、prometheus 的可规划清单；固定 x64 镜像版本并指定自定义模板 |
| [otel.template](templates/otel.template) | 将 collector.yaml 只读挂载至 /etc/otelcol-contrib/config.yaml |
| [collector.yaml](templates/collector.yaml) | 接收 OTLP gRPC :4317，将指标暴露于 :9464/metrics |
| [prometheus.template](templates/prometheus.template) | 将 prometheus.yaml 只读挂载至 /etc/prometheus/prometheus.yml，持久化 /prometheus |
| [prometheus.yaml](templates/prometheus.yaml) | 抓取 otel:9464，保留导出器的 job/instance 标签 |

`.settings` 只保存服务的 tag、repository、settings 默认值；不会选择服务，也不支持指定 template。仅在其中添加 otel/prometheus 还不够。手写清单和清单回放不合并 `.settings`，所以本清单显式固定了版本。修改镜像版本时同步核对这两个位置。

## 使用现有容器化工具

从 hosting 根目录规划（不创建、启动容器）：

```powershell
dotnet containerize plan .containerized/diagnostics.container --source:. --output:.containerized
```

规划后会生成 `.containerized/zongsoft-diagnostics@1.0-x64.container`。之后需要制作交付包时使用 `dotnet containerize make` 读取它；制作可能拉取镜像并执行构建，不属于此次源码改造的验证范围。

如果已有包含应用安装包的 `.container` 清单，把 [diagnostics.container](diagnostics.container) 中的 `[otel]`、`[prometheus]` 两节合入该清单，保留应用节、根字段与服务名，再规划、制作该清单。也可以先用现有交互入口生成包含 otel/prometheus 的计划，再为两节补上这里的 template 路径。不要只使用内置同名模板，它们没有引用这两个自定义 YAML。

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

## 验证范围

已运行真实 Containerizer 的 plan，检查两个模板及 YAML 输入存在；YAML 另做语法和结构检查。未运行 make/run、未拉取镜像、未启停容器。本机没有 promtool/otelcol 可执行文件，尚未用所选镜像校验完整配置或验证 Collector → Prometheus 的实际传输。
