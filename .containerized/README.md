# Collector and Prometheus container configuration

[English](README.md) | [简体中文](README.zh-Hans.md)

Containerizer uses these assets when a bundle includes otel and prometheus. OpenTelemetry Collector reads `collector.yaml`; Prometheus reads `prometheus.yaml`. Neither file is read by a daemon or terminal plugin.

## Configuration assets

| File | Purpose |
| --- | --- |
| [otel.template](templates/otel.template) | Read-only collector.yaml mount at /etc/otelcol-contrib/config.yaml |
| [collector.yaml](templates/collector.yaml) | Receive OTLP gRPC on :4317 and expose metrics on :9464/metrics |
| [prometheus.template](templates/prometheus.template) | Read-only prometheus.yaml mount at /etc/prometheus/prometheus.yml; persistent /prometheus data |
| [prometheus.yaml](templates/prometheus.yaml) | Scrape otel:9464 and preserve exported job/instance labels |

[.settings](.settings) supplies tag, repository, template and settings defaults without selecting services. Its otel/prometheus sections already point to the custom templates above. Keep the reviewed image tags and Prometheus storage setting there.

## Use the existing containerization tool

Run `containerize.cmd` from the hosting root, choose a complete build or `plan`, and enter `otel` and `prometheus` along with the other required services. Select application hosts in the next menu. Containerizer reads `.containerized/.settings` and records the custom template paths in the generated `.container` automatically.

To plan only these two services without creating or starting containers:

```powershell
dotnet containerize plan otel prometheus --name:zongsoft --distribution:debian@13 --architecture:x64 --source:. --output:.containerized
```

To include application packages in the same plan, add host directories such as `daemon` to the component list after preparing their packages. The generated `.containerized/zongsoft@<version>-x64.container` can then be passed to `dotnet containerize make`.

Saved or handwritten manifests do not merge `.settings`. Regenerate an old plan or edit its existing service sections to add the following entries, retaining the reviewed tags and settings:

```ini
[otel]
template=.containerized/templates/otel.template

[prometheus]
template=.containerized/templates/prometheus.template
```

These entries select templates; they do not replace the sections' other fields. The built-in templates with the same service names do not reference these custom YAML files.

Containerizer checks `[configuration]` input paths, copies the files into the bundle's `config/` directory and creates read-only mounts. YAML paths are relative to the template directory; template paths are relative to the final source. YAML contents are copied unchanged, without `${...}` expansion.

## Networking and host configuration

```text
daemon / terminal --OTLP gRPC--> otel:4317
Prometheus       --HTTP scrape--> otel:9464/metrics
Web + Diagnostics.Web <--HTTP scrape-- Prometheus (optional separate target)
```

- The container deployment scheme sets daemon/terminal to `server=http://otel:4317;protocol=grpc`. Applications and infrastructure must share a container network. Put them in the same container manifest for the simplest setup.
- With infrastructure only, local daemon/terminal use `http://127.0.0.1:4317`. The template publishes 4317 on host loopback; remote machines require a different publication address.
- Collector binds `0.0.0.0:4317` and `0.0.0.0:9464` inside its container. Prometheus uses 9464 on the shared network; no host publication is required. Only gRPC is enabled, not HTTP on 4318.
- Prometheus UI is published on `127.0.0.1:9090`. The `otel` in `otel:9464` is the Collector service, not localhost inside Prometheus.
- Web exposes port 9465 through Diagnostics.Web. All hosts share the common diagnostics template; Web site profiles set `diagnostics.telemetry:enabled=false` to prevent duplicate OTLP metric export. Add an actual reachable Web target to prometheus.yaml when needed, such as `zongsoft.web:9465` on the same network or a reverse proxy `/metrics` endpoint. No assumed Web target is enabled by default.

These templates handle metrics only; the host templates likewise enable only metrics. Traces and logs require additional receiver pipelines and backends; Prometheus does not store them. The common Diagnostics package retains trace export support.

The scrape `up` signal reports Collector availability, not every application's health. `metric_expiration: 2m` removes data that stops arriving. Application alerts need an expected service inventory, missing-metric rules or a dedicated heartbeat.

## Other container workflows

The existing `zongsoft.compose.yaml` and `zongsoft.pod-*.yaml` workflows remain available. These assets apply only to Containerizer manifests that select the custom templates; they are not added automatically to the existing Compose/Pod definitions. With manual Docker/Podman Compose, mount files at the paths above. With Kubernetes, provide them through ConfigMaps or equivalent and adjust service DNS. The infrastructure images do not contain this project's .NET plugins.
