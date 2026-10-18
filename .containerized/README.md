# Collector and Prometheus container configuration

[English](README.md) | [简体中文](README.zh-Hans.md)

Containerizer uses these assets when making an infrastructure bundle. OpenTelemetry Collector reads `collector.yaml`; Prometheus reads `prometheus.yaml`. Neither file is read by a daemon or terminal plugin.

## Configuration assets

| File | Purpose |
| --- | --- |
| [diagnostics.container](diagnostics.container) | Infrastructure-only manifest selecting otel and prometheus, pinned x64 images and custom templates |
| [otel.template](templates/otel.template) | Read-only collector.yaml mount at /etc/otelcol-contrib/config.yaml |
| [collector.yaml](templates/collector.yaml) | Receive OTLP gRPC on :4317 and expose metrics on :9464/metrics |
| [prometheus.template](templates/prometheus.template) | Read-only prometheus.yaml mount at /etc/prometheus/prometheus.yml; persistent /prometheus data |
| [prometheus.yaml](templates/prometheus.yaml) | Scrape otel:9464 and preserve exported job/instance labels |

`.settings` supplies only tag, repository and settings defaults. It neither selects services nor accepts a template field. Adding otel/prometheus there is insufficient. Handwritten manifests and manifest replay do not merge `.settings`, so this manifest explicitly pins versions. Check both locations when changing an image version.

## Use the existing containerization tool

Plan from the hosting root without creating or starting containers:

```powershell
dotnet containerize plan .containerized/diagnostics.container --source:. --output:.containerized
```

This generates `.containerized/zongsoft-diagnostics@1.0-x64.container`. Use it with `dotnet containerize make` when ready to make a delivery bundle. Making a bundle may fetch images and execute builds; it is outside this source change's validation scope.

For an existing application manifest, merge the `[otel]` and `[prometheus]` sections from [diagnostics.container](diagnostics.container), retaining its application sections, root fields and service names. Then plan and make that manifest. Alternatively, generate an interactive plan selecting otel/prometheus and add these template paths to the two sections. The built-in templates with the same names do not reference these custom YAML files.

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

## Validation scope

The actual Containerizer plan command checked both templates and YAML input paths. YAML syntax and structure were checked separately. No make/run, image fetches or container lifecycle operations were performed. promtool/otelcol are not installed locally; full configuration validation with the selected images and live Collector → Prometheus transport remain unverified.
