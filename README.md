[English](./README.md) | [简体中文](./README.zh-Hans.md)

-----

## Hosts

Applications are currently divided into three host types:

- Terminal applications
	> Run in a console and are suitable for debugging.

- Daemon applications
	> Compilation and deployment must target a specific operating-system platform, and the application runs under a platform-specific service manager.
	> - On Linux/Unix, the application is managed by systemd and requires the corresponding `*.service` file;
	> - On Windows, the application is managed by the Service Control Manager and installation must run with administrator privileges;
	> 	- Use [install.cmd](./daemon/install.cmd) to install the service;
	> 	- Use [uninstall.cmd](./daemon/uninstall.cmd) to uninstall the service.

- Web applications
	> Web backend applications are usually organized by site. Common sites include:
	> - administration
	> - business
	> - customer
	> - partner
	> - gateway
	> - IoT

## Deployment

Each plugin selects one configuration entry: first the `.option` with the same basename as its `.plugin` file, then `<plugin name="…">.option` only if the first file is absent. If neither exists, no configuration is loaded. The entries are not merged, suffix files are not scanned, and an invalid selected entry fails loading. Daemon, terminal and Web hosts use parameterless `LoadConfiguration()` to load the application-named `.option`, then also load the entry-assembly-named `.option` when the names differ. Web hosts subsequently load `web.option`; later files override earlier keys. Runtime environment, host and site values do not select files.

Fragments are explicitly imported with `<?import path="…" required="false"?>`, using paths relative to the declaring file. Imports at the end override earlier keys; `required="false"` permits a missing file but does not suppress invalid XML. Plugin environment fragments use `Name-${environment}.option`; network fragments use `Name-${environment}-${network}.option`. The main entry imports environment fragments, which import their network fragments. Ordinary XML import paths do not evaluate deployment variables; templates must render concrete paths at deployment time.

Deployment manifests copy only the selected environment and network fragments; each deployment directory contains one environment and network configuration. Configuration updates follow the deployment tool's overwrite policy without deleting target files first with `delete:`; manifests do not clean up legacy configuration. Ordinary entries may declare several optional environment imports, but only fragments present in the deployment directory are loaded. Update imports and deployment entries when adding configuration. `app.option.template` generates the host configuration using the entry assembly name, which is `Zongsoft.Hosting.Web.option` for Web hosts. `web.option.template` generates the independent `web.option` with site-specific Web configuration; no import of the shared host configuration is needed. Manifests only list configuration backed by actual assets or template outputs; they do not reserve copy, import or deletion entries for nonexistent files.

Daemon and terminal use only `Microsoft.NETCore.App`, deploying the common `Zongsoft.Diagnostics` package and exporting metrics through OTLP → Collector → Prometheus. `Zongsoft.Diagnostics.Web` and its Kestrel dependency are deployed only to Web hosts. The source versions are Diagnostics 1.13.0 and Diagnostics.Web 1.0.0; make the corresponding packages available before deployment.

All hosts render `Zongsoft.Diagnostics.option.template`. Scheme `.env` defaults set `[diagnostics.telemetry] enabled=true`; each Web site's `.env` sets `enabled=false` after importing its scheme. Disabled OTLP exporters do not run, while `Zongsoft.Diagnostics.Web.option.template` adds the Prometheus exporter for Web hosts. The common template's `server` selects Collector: `http://127.0.0.1:4317` for default and `http://otel:4317` for container. Web `[diagnostics.prometheus] server/port` defaults to `127.0.0.1:9465`, with `0.0.0.0` for containers and optional Nginx `/metrics` access. These host templates enable metrics only; tracing requires a separate backend. See the [.containerized guide](.containerized/README.md) for Collector/Prometheus YAML, custom templates and manifests.

The shared Diagnostics template now uses `driver="opentelemetry"`; Console exporters use `driver="opentelemetry.console"`. The plugin parses settings into typed models and keeps the legacy aliases `telemetry`, `OpenTelemetry`, and `Console`. Configuration entry names (`exporter.name`) and host variables under `diagnostics.telemetry` and `diagnostics.logging` are unchanged. Invalid types, out-of-range durations and invalid batch settings fail exporter configuration. See the [Diagnostics settings reference](https://github.com/Zongsoft/framework/blob/main/Zongsoft.Diagnostics/README.md#strongly-typed-exporter-settings) for parameters and defaults. Deploy the new configuration together with the Diagnostics plugin containing this change.

Logs use independent `[diagnostics.logging] enabled/server/protocol` settings and default to disabled. The server references the final `diagnostics.telemetry:server`; protocol defaults to grpc. Enabling logs activates `<logs>` in the common template and exports Microsoft `ILogger` records, honoring host `Logging:LogLevel`. Disabling Web OTLP metrics does not disable logs. The receiver must support OTLP logs; the existing Collector YAML remains metrics-only and requires a logs pipeline and log backend before accepting logs. Zongsoft logging is not bridged. Redeploy configuration and restart the host after changes.

Aliyun uses a single shared template, `Zongsoft.Externals.Aliyun.option.template`, to generate the complete `Zongsoft.Externals.Aliyun.option`. The scheme `.env` defines all defaults in `[aliyun]`; the selected `<environment>-<network>.env` overrides credentials, intranet access, and resource differences in the same `[aliyun]` section, while omitted settings retain their defaults. Variables are merged before rendering, so the final configuration contains only the OSS bucket, message queue, and topic selected by the current combination. Aliyun environment fragments are no longer generated or imported.

The host projects copy Main.plugin (plus Terminal.plugin for Terminal) into build and publish output. Local framework references use the framework source manifests; package references use the matching Zongsoft.Plugins package. Web deployment copies Main.plugin from its build output into the site plugin directory. Daemon and Terminal deliver the manifests with their build directory. This keeps base registration assets with the selected framework reference and removes separate NuGet manifest extraction.

Hosts initialize the runtime; plugins and their configuration, certificates, and other assets provide application features.

Run root [`deploy.cmd`](deploy.cmd) to choose a discovered host from a menu. Both deployment and packaging scan the calling directory and its subdirectories for `.deploy` files alongside `Zongsoft.Hosting.Daemon.csproj`, `Zongsoft.Hosting.Terminal.csproj`, or `Zongsoft.Hosting.Web.csproj`. Hosts such as `daemon`, `terminal`, and `web/default` appear automatically, including newly added sites. Hidden directories, directory links, `bin`, `obj`, `packages`, and `node_modules` are skipped. `deploy.cmd web/default` preselects a source relative to the calling directory; absolute paths are also accepted. The script asks for scheme, environment, network, build configuration, platform, and architecture. It runs Cake inside the selected host, then executes that host's `.deploy` through `dotnet deploy --source:<host> --output:<target>`.

For local Debug deployment, run [daemon/deploy.cmd](daemon/deploy.cmd), [terminal/deploy.cmd](terminal/deploy.cmd), or [web/default/deploy.cmd](web/default/deploy.cmd). These shortcuts call root `deploy.cmd <source> --local`, fixing the source to their own host directory and using `configuration=Debug`, `platform=windows`, `architecture=x64`, and the existing framework defaults without prompting for these settings. They use `--overwrite=alway` to always overwrite existing files. Only scheme, environment, and network retain their usual prompts and defaults. Calling a shortcut from another directory still selects its own host.

Host menus follow the directory hierarchy. Only actual hosts have numbers; parent directories such as `web` are non-selectable group headings and arrow keys skip them. Deployment and packaging select one host at a time, for example:

```text
1. daemon
2. terminal
web
  3. default
```

Each deployment selects one environment and one network. Network internal/external selects service connectivity. Build configuration (Debug/Release) and target platform are selected independently; the general script defaults to Release and Linux. Deployer does not encode these combinations or prescribe output directories. The script uses `bin/${edition}/${framework}` for daemon/terminal and the host root for Web; direct tool calls may choose any `--output`. Deployer processes assets declared by `.deploy`; Cake builds the host.

Root deployment and local Debug shortcuts both use `--overwrite=alway` (the deployer enum for always overwrite; it does not accept `true`). Both use `--prerelease:true --verbosity:quiet`. Build or deployment failure stops the sequence and identifies the failed stage and original exit code. Successful deployment returns 0. Run root [`pack.cmd`](pack.cmd) separately to create an installation package. Both scripts preserve the caller's directory and environment.

`deploy.cmd`, `pack.cmd`, `containerize.cmd`, and `migrate.cmd` launch their corresponding Windows PowerShell scripts: [`deploy.ps1`](deploy.ps1), [`pack.ps1`](pack.ps1), [`containerize.ps1`](containerize.ps1), and [`migrate.ps1`](migrate.ps1). Each PowerShell entry point owns its tool's workflow and arguments, and dot-sources [`.shared.ps1`](.shared.ps1) for headings, prompts, menus, host discovery, tool execution, and error handling. The shared script does not dispatch tool operations or run a workflow when loaded.

The layout uses cyan section titles, gray hints below each input, highlighted menu selections, and an execution summary. Use Up/Down or Home/End to choose, Enter to confirm, and Esc in a menu to cancel (exit code 2). Redirected input or output uses numbered choices; an empty answer selects the default, and exhausted input cancels before execution. Redirected output is plain text; `NO_COLOR` disables console colors. Deployment and packaging wait for a key after interactive success or failure; redirected runs do not pause.

Framework is no longer prompted. The scripts read the literal root-level `framework` entry in hosting/.env and pass that value to Cake, deployer, and packager, including local Debug shortcuts. Keep this entry as a target framework name rather than a template expression. Other `.env` variables and imports remain the responsibility of the tools; scripts do not export the file into the process environment.

Deployment and packaging select Scheme from the immediate directories of hosting/.deploy whose names do not start with a dot; the default is `default` when present, otherwise the first directory by name. Migration uses the same Scheme menu. Environment offers Development, Test, and Production; values passed to tools and configuration paths remain lowercase. A matching process `Environment` value is preselected; otherwise Development is selected. Network defaults to internal.

Package identity is defined in the host `.env` under `[application]`; the script explicitly passes `${application:name}`, `${application:title}`, and `${application:daemon}`. Daemon uses zongsoft.daemon; terminal uses zongsoft.terminal with services disabled. Web uses entry name Zongsoft.Hosting.Web, title Zongsoft.Web, and service zongsoft.web. Services receive Environment and DOTNET_ENVIRONMENT; Web also receives ASPNETCORE_ENVIRONMENT.

See the [deployer documentation](https://github.com/Zongsoft/tools/blob/main/deployer/README.md) for syntax, templates, plans, and locks.

### Local Plugin Verification and Startup Troubleshooting

Features come from plugins and configuration; the host Program need not reference every implementation. Business code should depend on Core/shared module interfaces and obtain implementations through `ApplicationContext.Current.Services`, the application's own `Module.Current.Services`, or a configured provider. See [Core service lookup](https://github.com/Zongsoft/framework/blob/main/Zongsoft.Core/README.md) and the [plugin deployment guide](https://github.com/Zongsoft/framework/blob/main/Zongsoft.Plugins/README.md).

1. Prepare an isolated deployment. Review its manifests and startup workers, including only required plugins and test configuration.
2. Build or publish a compatible launcher. When copying debug output, retain `*.deps.json`, `*.runtimeconfig.json`, dependency DLLs, `runtimes/`, and resource directories, not just the main DLL.
3. Run from the deployment directory. The default content root depends on the working directory; invoking an absolute DLL path from elsewhere does not change it and may report a missing `plugins` directory.
4. A Windows terminal host needs valid console handles. Use an interactive terminal or PTY/ConPTY; a console-less pipe can fail with an invalid-handle error. Use a daemon/Web launcher for unattended hosting.
5. Verify the plugin list, configuration, and service lookup before connecting to authorized local infrastructure. Record expected and actual results without logging credentials or business data.
6. Exit with `exit -yes`. Clean up only this verification's data and resources you started.

🚨 Successful plugin loading does not prove runtime dependencies are complete. An older host Core can cause assembly-loading errors during service scanning; missing `runtimes` assets can break platform dependencies; transitive dependencies can overwrite a shared SDK and cause missing-method errors on first use. Preserve the first error and inspect **final deployed files**, not just project references or build success.

The terminal entry point appends `host=terminal` and `site=daemon`. These remain available as application context values; they do not select option files; the deployer's `--site` operates at a different stage.

For a minimal HTTP check, follow the [decoupled Web plugin example](https://github.com/Zongsoft/framework/blob/main/Zongsoft.Plugins.Web/README.md). Controller discovery does not create a missing route template: the default host uses `MapControllers()`, so verify a real response instead of just the plugin list. In manual native-plugin deployments, retaining `runtimes/` can be necessary but not sufficient; verify the actual native search layout. A Windows x64 SQLite probe required its matching `e_sqlite3.dll` beside the managed SQLite components.

### Deployment Files

`hosting/daemon/.deploy`, `hosting/terminal/.deploy`, and `hosting/web/default/.deploy` declare deployment assets. Their `${scheme}` references select scheme directories; the tool gives `.deploy/` no special directory semantics.

### Configuration reuse

```text
hosting/
  .env                         # Common variables for explicit imports
  deploy.cmd
  pack.cmd
  .deploy/
    .env                       # Explicitly imported connection expressions
    .shared/                   # app, Web, diagnostics, and Aliyun templates
    default/
      .env                     # Scheme values and explicit imports
      development-internal.env
      development-external.env
      production-internal.env
      production-external.env
      test-internal.env
      test-external.env
      migration/               # Migration inputs
    container/
      .env                     # Default combination plus container service addresses
  daemon/
    .env                       # Import common and scheme variables, then host values
    .deploy
  terminal/
    .env
    .deploy
  web/
    .env                       # Shared Web variables
    default/
      .env
      .deploy
```

Tools load only the selected source directory's `.env` (the working directory for migrator). Each host first imports `../.env`: daemon and terminal read the hosting root, while Web sites read `web/.env`, which in turn imports the hosting root. Hosts then import the selected scheme and declare their own values.

The `[web]` section in `hosting/web/.env` supplies `url=http://*:8069/` and `protocols=http1`. Deployment renders these values and a zongsoft.tools.binding processing instruction into `web.option`. Packager reads the same configuration as the host, and does not add `--urls`. The file is generated from `.deploy/.shared/web.option.template` on every deployment and ignored by `web/.gitignore`.

For example, `hosting/daemon/.env` contains:

```ini
#@import ../.env
#@import ../.deploy/${scheme}/.env

host=daemon
site=daemon

[application]
name=zongsoft.daemon
title=Zongsoft.Daemon
daemon=zongsoft.daemon
```

`hosting/.deploy/.env` explicitly imports the hosting root's `../.env` before declaring shared connection expressions, so scheme directives can resolve default environment/network values. `hosting/.deploy/default/.env` imports that shared file, defines scheme values, then selects one combination with `#@import ${environment}-${network}.env`. Imported files do not trigger their own ancestor search. Later same-key declarations within a Profile override earlier ones: project values after an import can override the scheme, or a later import can override project values. The tool does not prescribe project/scheme precedence.

The default scheme's `.env` supplies the complete baseline required by the shared service connection expressions, including the local `network:server` and Aliyun `intranet` defaults. Each `<environment>-<network>.env` lists every remote service endpoint, supported port, username, password, token, or access key, even when equal to the defaults. Common settings such as character sets, timeouts, and compression stay in `.env`. The six files cover development, test, and production with internal and external access. Each combination file defines its shared host as `server` in `[network]`. Services on that host reference `${network:server}` while retaining their own URL scheme, port, and path; services on a dedicated host retain their own address. The container scheme inherits the selected default combination before overriding service addresses. Additional service defaults do not enable their plugins or start services; configure their addresses and credentials before use.

Shared templates hold structure and variables hold values. For example, `.deploy/.shared/app.option.template` references `${mysql:connection#xml}`; `.deploy/.env` composes the connection expression and scheme files supply service addresses and other values. `#xml` escapes XML characters; Core performs recursive evaluation. `.env` is never deployed. Template output drops `.template` or uses the explicit destination name from `.deploy`.

Database connections cover all eight drivers in `Zongsoft.Data/drivers`. `.deploy/.env` holds connection expressions, `.deploy/default/.env` supplies scheme values, and `app.option.template` writes `/Data/connectionSettings`. The default remains the MySQL connection named `Zongsoft`; other connections use `Zongsoft.<driver>`. Deploy the corresponding driver plugin in the host’s `.deploy` before using a connection.

| Variable namespace | driver | Settings definition and differences |
| --- | --- | --- |
| `mysql` | `MySql` | [MySqlConnectionSettings](https://github.com/Zongsoft/framework/blob/main/Zongsoft.Data/drivers/mysql/src/Configuration/MySqlConnectionSettings.cs) |
| `postgres` | `PostgreSql` | [PostgreSqlConnectionSettings](https://github.com/Zongsoft/framework/blob/main/Zongsoft.Data/drivers/postgres/src/Configuration/PostgreSqlConnectionSettings.cs): separate `Port`, default 5432 |
| `mssql` | `MsSql` | [MsSqlConnectionSettings](https://github.com/Zongsoft/framework/blob/main/Zongsoft.Data/drivers/mssql/src/Configuration/MsSqlConnectionSettings.cs): the complete endpoint goes in `Server`; no separate `Port` setting |
| `sqlite` | `SQLite` | [SQLiteConnectionSettings](https://github.com/Zongsoft/framework/blob/main/Zongsoft.Data/drivers/sqlite/src/Configuration/SQLiteConnectionSettings.cs): `Database` is a file path; the sample `ReadWriteCreate` permits creating a missing file |
| `duckdb` | `DuckDB` | [DuckDBConnectionSettings](https://github.com/Zongsoft/framework/blob/main/Zongsoft.Data/drivers/duckdb/src/Configuration/DuckDBConnectionSettings.cs): defines only `Database`, mapped to the provider’s `DataSource` |
| `clickhouse` | `ClickHouse` | [ClickHouseConnectionSettings](https://github.com/Zongsoft/framework/blob/main/Zongsoft.Data/drivers/clickhouse/src/Configuration/ClickHouseConnectionSettings.cs) |
| `tdengine` | `TDengine` | [TDengineConnectionSettings](https://github.com/Zongsoft/framework/blob/main/Zongsoft.Data/drivers/tdengine/src/Configuration/TDengineConnectionSettings.cs) |
| `influx` | `Influx` | [InfluxConnectionSettings](https://github.com/Zongsoft/framework/blob/main/Zongsoft.Data/drivers/influx/src/Configuration/InfluxConnectionSettings.cs): InfluxDB 3 URL, `Token`, `Organization`, and `Precision` |

Passwords for the added database servers and the Influx Token are empty for the scheme to supply. SQLite and DuckDB relative file paths are interpreted by their database providers at application runtime, not relative to the deployment source; neither needs a server or account. These two local database providers need no entries in the combination files. MySQL, PostgreSQL, ClickHouse, and native TDengine expose separate ports, defaulting to 3306, 5432, 8123, and 6030; the shared connection expressions include these port variables.

The S3 file system uses `[amazon.s3]` and `${amazon.s3:connection}`. The template writes `/Externals/Amazon/connectionSettings` with driver `amazon.s3`. Fields follow [S3ConnectionSettings](https://github.com/Zongsoft/framework/blob/main/externals/amazon/src/IO/Configuration/S3ConnectionSettings.cs): `Server`, `Region`, `AccessKey`, `SecretKey`, `AccountId`, `Client`, and `Timeout`. The default scheme uses the network address on port 9000 and reuses `${rustfs:access_key}` and `${rustfs:secret_key}` from the hosting root `.env`. An AWS S3 scheme can leave server empty and configure its region and credentials; a custom server automatically enables path-style addressing in the driver. The bucket belongs in the `zfs.s3:/<bucket>/<key>` path, not in the connection settings.

Etcd uses `[etcd]` and `${etcd:connection}`. The template writes `/Externals/Etcd/connectionSettings` with driver `Etcd`. Following [EtcdConnectionSettings](https://github.com/Zongsoft/framework/blob/main/externals/etcd/src/Configuration/EtcdConnectionSettings.cs) and client construction, the connection supplies `Server`, `Port`, `UserName`, and `Password`; the default port is 2379 and credentials are empty. The server may be overridden with a comma-separated endpoint list. Applications still set `EtcdService.Namespace` for key isolation; the connection name is not a key prefix.

Message-queue connections use the `messaging.mqtt`, `messaging.kafka`, `messaging.rabbitmq`, `messaging.zeromq`, and `messaging.redis` namespaces. `.deploy/.env` defines connection expressions, the scheme `.env` supplies values, and `app.option.template` writes them to `/Messaging/connectionSettings`. The default scheme supplies local examples for the added queues: Kafka on port 9092 with Plaintext, RabbitMQ on port 5672 with virtual host `/` and the default guest account, and ZeroMQ discovery on port 7969. Override these values for the actual scheme. Redis and Redis messaging also expose optional usernames. Redis, MQTT, and Kafka accept ports inside `server`; SQL Server keeps its complete endpoint in `server`, while S3 and Influx use URLs. RabbitMQ, Etcd, and ZeroMQ use their separate port fields. Keep all ZeroMQ discovery, control, incoming, and outgoing ports in each combination file.

All three hosts render `.deploy/.shared/Zongsoft.Messaging.ZeroMQ.option.template` as the plugin client configuration, replacing the package sample that would otherwise override the host connection with loopback. The `daemon` host runs the independent ZeroMQ server and also renders `Zongsoft.Messaging.ZeroMQ-daemon.option.template`. The daemon template declares one `/Messaging/ZeroMQ/Server` with `name="QueueServer"`, `enabled="true"`, and `storage="QueueServer"`. Its Control, Incoming, Outgoing, and Discovery addresses use complete `tcp://0.0.0.0:<port>` URLs, with ports supplied by `messaging.zeromq:control`, `incoming`, `outgoing`, and `port` respectively (32100, 32101, 32102, and 7969 by default). Four `zongsoft.tools.binding` instructions read those same server settings and filter on `enabled:true`; their `\${this.*}` expressions are escaped in the deployment template so that the generated option retains `${this.*}` for binding evaluation. Control and Storage must be configured together, and the storage factory must resolve the Redis connection named `QueueServer`. Clients use the discovery host for all four roles, so publish the same four TCP port numbers. A general Redis connection named `Zongsoft` does not satisfy the server's named storage lookup. Set a stable `ZONGSOFT_MESSAGING_STORAGE_IDENTIFIER` in the daemon process environment so that recreating the daemon preserves its Redis storage partition.

The `container` scheme keeps only `.deploy/container/.env`, which imports the complete `default` settings and the selected `<environment>-<network>.env` before overriding Redis, MySQL, RustFS, and Etcd addresses with container service names. Shared templates generate the host and infrastructure configurations from these merged values. Ports, credentials, and endpoints for services hosted elsewhere remain inherited from the selected combination. Its ZeroMQ clients use `zongsoft.daemon`; `daemon/.env` overrides that client's address to `127.0.0.1` because the server runs in its own process. Container Web and local Debug Web can share this daemon: container clients use the service name, while the default local scheme uses loopback and the published TCP ports. Deploy and package the daemon before making a delivery that includes it.

Aliyun deploys one complete configuration. The selected `<environment>-<network>.env` supplies credentials, buckets, accounts, queues, topics, and `aliyun:intranet` in `[aliyun]`. These values override the scheme defaults before rendering; omitted settings retain their defaults. The default scheme retains local sample addresses; real schemes must define service addresses for each network. Debug mode does not select the network. Optional ordinary Security, Hangfire, and other configuration can still be supplied at paths declared by `.deploy`.

For a new scheme, put its `.env`, `<environment>-<network>.env` combination files, certificates, plugins, and other unique assets under `.deploy/<scheme>/`, reusing `.shared` templates. Optional `${host}.deploy` and Web `${site}.deploy` files can extend deployment. Shared certificates may live under `.shared/certificates/` and be explicitly referenced. Environment and network require no extra directory hierarchy.

Direct deployment example, processing declared assets only:

```powershell
dotnet deploy --source:daemon --output:'bin/${edition}/${framework}' --scheme:default --environment:production --network:internal --edition:Release --platform:linux --architecture:x64 --prerelease:true
```

`--source` is relative to the invocation directory. Local relative inputs and output use source; paths inside `.deploy` and imports use the declaring file. Add `--dry-run --report:plan.json` to inspect the plan; report paths also use source.

The shared application template uses `Zongsoft` (MySQL) as the default database connection. Other databases use independent names such as `Zongsoft.PostgreSql` and `Zongsoft.MsSql`, selected explicitly by an application. Do not use `Zongsoft#...` for alternatives: `#` groups sources and includes those connections in the default query.

### Deployment Tool

Before running `deploy.cmd`, make sure the deployer tool is installed. Use the following command to list installed global tools:

```bash
dotnet tool list -g
```

If the deployer is not installed, install it globally:

```bash
dotnet tool install -g zongsoft.tools.deployer
```

If it is already installed, update it with:

```bash
dotnet tool update -g zongsoft.tools.deployer
```

> 💡 For more information about the design and implementation of **Z**ongsoft.**T**ools.**D**eployer, visit its open-source repository: [https://github.com/Zongsoft/tools/deployer](https://github.com/Zongsoft/tools/tree/main/deployer)

-----

> 💡 To build and debug the [**Z**ongsoft framework source](https://github.com/Zongsoft/framework) locally, install [**C**ake.**T**ool](https://cakebuild.net/docs/getting-started/setting-up-a-new-scripting-project):
> ```bash
> dotnet tool install -g cake.tool
> ```

## Installation and migration packages

### Tools and shared variables

The [packager](https://github.com/Zongsoft/tools/tree/main/packager) command `dotnet-pack` creates installation packages; the independent [migrator](https://github.com/Zongsoft/tools/tree/main/migrator) command `dotnet-migrate` creates migration archives. Install or update the global tools as needed:

```powershell
dotnet tool install -g Zongsoft.Tools.Packager
dotnet tool install -g Zongsoft.Tools.Migrator
# For an installed tool, use dotnet tool update -g <package-name>
```

Set `framework` at the root level of the hosting root's `.env`, for example:

```ini
framework=net10.0
```

Tools query explicit command options, the source directory's `.env` and its explicit imports (working directory for migrator), then process environment variables. Deployer also checks destination appsettings immediately after command options. Core queries descriptor defaults only after all ordinary sources miss. Every variable, including `framework`, treats explicit null or empty values as a successful lookup that stops fallback; operations validate the values they require. Profile sections are variable namespaces: `[mysql] root_password` is referenced as `${mysql:root_password}`; nested sections use dots and entry dots/hyphens become underscores. Tools explicitly enable variable fallback. Named references query every source at the current namespace before moving through parents to global. Source priority applies within each namespace and any success, including null, stops lookup. Declared option defaults apply only after all ordinary global queries also miss.

Templates follow Core `${name}` / `${namespace:name}` syntax and escaping. Prefer relative paths; use `/` for absolute paths. `#@import ../.shared/${product}.env` is evaluated when encountered and imports one complete path. It can use explicit command options, earlier entries and completed imports, but not later declarations. Profile itself retains raw values.

Prepare deployment environment variables in the current PowerShell window, then enter the target host directory:

```powershell
$env:Environment = 'development'
Set-Location D:/Zongsoft/hosting
.\deploy.cmd
```

Root scripts select the environment from Development, Test, and Production. A matching process Environment is preselected; otherwise Development is the default. Values passed to tools are lowercase.

### Container delivery

The maker reuses the hosting root's `.env` through its existing Profile variable pipeline. Use explicit variable references in the .container manifest and templates to reuse settings; CMD does not parse .env or export credentials.

The built-in MySQL template binds `[mysql] root_password` from `.env` to `MYSQL_ROOT_PASSWORD`. An explicit `settings=root-password=...` or `environment!MYSQL_ROOT_PASSWORD=...` in the component overrides it. Other settings still require an explicit variable reference or template binding.

Install/update the global `Zongsoft.Tools.Containerizer` tool separately. `containerize.cmd` directly calls `dotnet-containerize` on PATH, without probing tool locations. The maker's [README](https://github.com/Zongsoft/tools/tree/main/containerizer) describes local compilation and global installation.

Run `.\containerize.cmd` to choose a complete build, `plan` (editable manifest only), `make` (build from a manifest), or `run` (verify a delivery locally). The existing distribution/architecture/engine menus remain available for new selections. Scripts do not ask for individual service settings; maintain `.containerized/.settings`, then edit the generated `.container` for per-delivery changes.

```cmd
containerize.cmd plan
containerize.cmd make .containerized\zongsoft@1.0-x64.container
containerize.cmd plan .containerized\zongsoft@1.0-x64.container --version:1.1
containerize.cmd make .containerized\zongsoft@1.0-x64.container --version:1.1
```

Use `containerize.cmd --refresh` to enter the existing menu and refresh public runtime environments for this complete build or make; plan/run do not refresh, and normal startup reuses valid environments. Direct invocation also accepts `containerize.cmd make FILE.container --version:1.1 --refresh`. The option is not written to `.container` and does not change pinned infrastructure digests; application images are rebuilt from the current packages each time.


The last two lines are alternative ways to create a new release. A named subcommand followed by inputs/options runs without the new-delivery prompts; a single `.container` argument remains shorthand for `make`. Interactive `make` lists the `*.container` files directly inside `.containerized`, sorted by filename, followed by a manual-path option. Only that last option prompts for a path; when no files are found, it is the only choice. After selecting a manifest, you can enter an optional new release version. This menu also appears for `containerize.cmd make` without a path. Saved selections are retained; interactive reuse only asks for an optional new release version. Use direct arguments to override the engine. Source is fixed to the hosting directory and output to `.containerized`. The script restores the calling directory/environment.

After a complete build, plan or make, the script displays an explicit success message or a failure message with the original tool exit code. Tool diagnostics remain visible. Interactive success and failure screens wait for a key before exiting. Redirected runs do not pause, and exhausted input cancels before execution.

The script groups operation selection, delivery settings, inputs and execution results into labeled sections. Titles are bold cyan, helper/key instructions are gray, and the selected menu row has a highlighted background. Success, warnings and errors use green, yellow and red, with explicit status markers. Default/key instructions appear below each text input, aligned with the field label; type directly after the field name and colon (for example, `Application name: `). Press Enter to continue, with one blank row between consecutive inputs. Redirected output stays plain text; set `NO_COLOR` to disable script colors in a console. Arrow-key navigation, Esc/back, literal paths, direct arguments and tool exit codes retain their behavior.

When creating a delivery, the migration directory menu offers three choices: no migrations (default), `.migration` under the hosting directory, or manual entry. Empty or whitespace-only manual input also disables migrations; press Esc during manual entry to return to this menu.

New selections default to application name `zongsoft`, Debian 13, x64, automatic engine selection and offline bootstrap/images. An empty release version uses a date version; existing delivery archives are never overwritten. Prepare installation packages with deploy.cmd/pack.cmd and migrations with migrate.cmd first; containerize.cmd does not compile hosts or generate migrations. For container deliveries, leave the Migration prompt in `pack.cmd` empty and select `.migration` in `containerize.cmd`; Containerizer runs the migration after infrastructure is ready. Packager-integrated migrations are for direct installation of application packages.

Next, enter basic services one per line (such as redis, mysql, rustfs, otel, or prometheus) and finish with an empty line. Then choose applications from the discovered host hierarchy. Space toggles a host and Enter confirms; multiple hosts or no hosts may be selected. Redirected input accepts comma-separated host numbers (such as `1,3`) or full relative paths; an empty answer selects no hosts. Choose at least one service or host; group headings such as `web` cannot be selected.

Host discovery is shared with deployment/packaging, and the tool still receives full relative paths such as `web/default`. Use direct commands such as `containerize.cmd plan <input> ...` for explicit installation packages or other directories; choose existing `.container` files through make.

The image delivery option is `--imaging:online|offline`, with matching root/service `imaging` entries in `.container`; `bootstrap` still controls engine dependencies independently.

`.containerized/.settings` stores infrastructure defaults. It preserves the existing image tags and references root `.env` variables for Redis, MySQL and RustFS secrets. Redis defaults to persistent storage and both RDB/AOF; edit a planned manifest to use `storage=temporary;persistence=none` for a particular test build. No password values are copied into shared settings. Other services' required parameters still need to be supplied when selected.

The `otel` and `prometheus` sections also set `template=.containerized/templates/<service>.template`. Selecting these service IDs automatically includes the corresponding project templates in a new plan or complete build. Template paths are relative to the hosting source; companion YAML files are relative to their template directory. Existing manifests keep their recorded selection and must be edited or regenerated to adopt these defaults. See the [configuration guide](.containerized/README.md).

For packaged Web applications, Nginx listeners and route references come from the package's root `.bindings` JSON. The three package formats carry the same document as a regular file. Application bindings proxied by Nginx remain internal by default; other bindings use same-number loopback publication. An application component can override this with `publish!<binding-id-or-alias>=auto|none|transport://IP:port`; `none` leaves proxy routes intact. Health defaults to process liveness, with an explicit JSON `health` command available. TCP and UDP at the same port are distinct publications; QUIC is not checked with a TCP probe. With no port override, every supported listener is published, including 80 and 8080 when declared. Nginx settings use `settings=port=80:18080,443:none`: container 80 prefers host 18080, while 443 stays internal. A saved `.container` must contain this syntax directly; `port=127.0.0.1:80` is invalid for Nginx. Changing `.settings` does not change a saved manifest.

`plan` creates only `name[-tag]@version-architecture.container`, without using an engine or resolving image digests. Missing required parameters produce magenta warnings and a successful draft; fix them before `make`. `make` ignores subsequent changes to shared `.settings`, resolves variables, and publishes the completed manifest plus its `.tar.gz` only after success. Failed builds retain the draft. The archive includes English/Chinese READMEs and an identical completed manifest. Shared settings can be version controlled; generated archives remain ignored.

Interactive run lists the hosting root's `.containerized/*.tar.gz`, ending with manual path entry. Esc returns from manual input to file selection, then to the operation menu. `containerize.cmd run FILE.tar.gz [--engine:podman]` runs directly without build options or a version prompt. The tool prints actual local Web/TCP mappings and interface addresses whose LAN reachability has not been probed; keep the window open and use Ctrl+C to remove the environment and test data. First base preparation may need Internet access. Web publication requests all IPv4 interfaces from the engine; LAN access also depends on host/VM forwarding and firewall rules. Web probes preserve Host/SNI and certificate validation while connecting to the actual local mapping. See the maker's run documentation for verified platforms and failure inspection.

The build branches do not perform onsite installation or service control. The run branch installs inside a disposable local verification container. Runtime health checks validate process/listener liveness, not business readiness; see the maker's platform acceptance matrix before selecting a deployment combination.

Deploy container applications with scheme `container` and local Debug hosts with `default`. `.deploy/container/.env` imports `.deploy/default/.env`, overriding only the configured container connections with service names `redis`, `mysql`, `rustfs`, and `etcd`; credentials and other settings remain inherited. Inside an application container, `127.0.0.1` addresses that application. The host-side migration executor uses the default scheme's loopback endpoints through published infrastructure ports.

### Create an installation package

From the hosting root, run deploy.cmd and select source, scheme, environment, network, build configuration, platform, and architecture. For Linux installation verification choose Release, linux, and the matching architecture. Failure stops subsequent stages.

After deployment, run root `pack.cmd` separately. Select the same host, compilation configuration, architecture, scheme, environment, and network, then choose tar, deb, or rpm. This script packages existing files only:

```powershell
Set-Location D:/Zongsoft/hosting
.\pack.cmd
```

| Standalone `pack.cmd` parameter | Default or behavior |
| --- | --- |
| Format | `tar`; also supports `deb` and `rpm`. All three set the target platform to Linux |
| Edition, version | May be empty; resolved from the host source directory's direct `.edition` (preferred) or `.version`. Edition is separate from the Debug/Release build configuration |
| Environment | See above; passed as `Environment` and `DOTNET_ENVIRONMENT`, plus `ASPNETCORE_ENVIRONMENT` for Web |
| Build configuration | `Release`; `Debug` is supported and must match existing output |
| Architecture | `x64`; `arm64` is supported and must match the application and migration executor |
| Source | Choose a discovered host; `daemon` is selected initially when available, otherwise the first host. `pack.cmd <source>` preselects a directory |
| Scheme, network | default, internal; match existing deployment, as packaging does not render configuration again |
| Framework | Read automatically from the root-level `framework` entry of hosting/.env; no prompt |
| Output directory | .packages, relative to selected source |
| Migration input name or path (`--migration`) | Empty skips integration; for example `zongsoft`. See below |

| Host | Application name / service | Payload and default installation directory |
| --- | --- | --- |
| daemon | `zongsoft.daemon` / `zongsoft.daemon.service` | Flattened `bin/${compilation}/${framework}`; `/opt/zongsoft/daemon` |
| terminal | `zongsoft.terminal` / service disabled | The same flattened build directory; `/opt/zongsoft/terminal` |
| web/default | `Zongsoft.Hosting.Web` / `zongsoft.web.service` | MIME files, configuration, wwwroot, plugins, and the flattened build directory; `/opt/zongsoft/web`, application listener `http://*:8069/` |

All scripts exclude `logs/`; Web additionally excludes build-directory `*.staticwebassets.*` and `plugins/**`, because its deployed site plugin directory supplies the plugin payload. Web explicitly includes generated `web.option` and `${application:name}.option`. The `:~` alias places directory contents at the installation root without retaining the original `bin/...` hierarchy. See the [Web README](web/README.md#packaging-the-default-site) for its service and Nginx configuration. Terminal disables systemd services, so `--daemon-environments` does not set process variables for an interactively launched terminal.

Output defaults to the selected host's `.packages/`, for example `zongsoft.daemon@1.0.0-x64.deb`; a nonempty Edition is appended to the package name. Tar produces a matching `.tar.gz` archive and `.sh` installation entry; keep both together. Deb/rpm each produce one package file. Packaging passes `--overwrite=true` to replace outputs with the same name; the tar archive and its installer are replaced together.

After successful packaging, an existing source `.edition` and `.version` are both rewritten, creating `.version` if absent. If only `.version` exists, only it is updated; if neither exists, both are created together. The installation payload always contains `.version` for the final identity and excludes the source directory's direct `.edition`. Installing or upgrading an installation package is a separate action; these scripts do not install it.

### Create a migration package before installation-package integration

Run `migrate.cmd` from the hosting root. Enter the migration name (default `zongsoft`), optional Edition, required version number/version file/directory, platform (default `linux`), architecture (default `x64`), and scheme (default `default`). Empty input at the first path prompt selects `.deploy/${scheme}/migration/${version}/*.migration`; alternatively, supply files one by one and then finish with empty input. A filename without directory separators resolves under that scheme/version directory; relative paths with directories resolve from the hosting root. Bare `*` is rejected; use `*.migration`.

Migration prompts share the interaction and execution helpers in `.shared.ps1`: bold cyan headings, cyan fields, gray hints, and green/yellow/red `[OK]`/`[WARN]`/`[ERROR]` markers. Hints appear below each text input, aligned with the field label; type directly after the field name and colon, then press Enter to continue. Consecutive input fields are separated by one blank row. Redirected output remains plain text; `NO_COLOR` disables script colors. Platform and architecture use the same arrow-key menus. File input still accepts `.migration` paths/patterns, without host selection. Success exits normally; interactive failures retain diagnostics, wait for a key, and return the original exit code. Redirected runs do not pause, and exhausted input cancels.

For example, create the default Linux x64 migration package from the hosting root:

```powershell
dotnet-migrate --name:zongsoft --version:1.0.0 --platform:linux --architecture:x64 --scheme:default --output:.migration '.deploy/${scheme}/migration/${version}/*.migration'
```

This produces `.migration/zongsoft(migrate)@1.0.0_linux-x64.tar.gz` and its matching `.sh`. Windows x64 produces a `win-x64` archive and `.cmd`; Linux also supports arm64. Creation parses inputs, expands variables, and packages files without connecting to or changing databases/buckets. The script has no overwrite switch; to recreate an existing output, invoke the tool directly with explicit `--overwrite`.

The default version directory contains MySQL and Amazon S3 inputs; connection parameters are in `.deploy/default/migration/*.ini`. The archive root contains `migration.json`, `id`, the internal launcher, the native executor, and its dependencies. SQL files are under `.artifacts/mysql/`, without a `.migration` wrapper.

Next, enter `zongsoft` at the migration prompt in root `pack.cmd`. The scripts pass this input to `dotnet-pack` through `--migration`. The packager searches the host source directory and its ancestors, including each direct `.migration/`, for a matching pair using the final Edition, version, and RID. Both files must come from the same location and match completely. An input with a directory checks only that directory, for example `../.migration/zongsoft` from daemon or `../../.migration/zongsoft` from Web. This option does not create migration artifacts.

The installation package carries the archive and external launcher unchanged under its installation root's `.migration/`. At execution, the launcher extracts to a separate temporary directory, with the plan and executor at its root, and cleans it afterward. Installation runs `apply` with state under `/var/lib/<package-name>/packager`; a failed migration prevents service startup. Before starting, systemd runs `check` against the local completion marker. Terminal also runs an integrated migration at installation despite disabling daemon support. SQL scripts themselves must make repeated execution safe.

### Package metadata and dependencies

The current hosting scripts have no separate prompts for homepage, manufacturer, maintainer, or dependencies. Set root-level `homepage`, `manufacturer`, `maintainer`, and `dependencies` variables in an applicable `.env`, or invoke `dotnet-pack` directly with these options. The homepage option is `--homepage`; `--manufacturer` and `--maintainer` both default to `Zongsoft`. A null or empty manufacturer also uses the default; whitespace is preserved.

Deb/rpm share the `--dependencies` syntax `name[:range]`, for example `--dependencies:"aspnetcore-runtime-10.0:[10.0,11.0)"` or `--dependencies:"aspnetcore-runtime-10.0:[10.0)"`. Commas/semicolons outside a range mean all groups are required; `|` means alternatives. The packager converts this to Debian `Depends` and RPM `Requires` without mapping distribution package names. RPM alternatives require 4.13+, and bounded ranges require 4.14+. See the packager's bilingual README for complete rules.

`upgrade.pack.cmd` / `upgrade.publish.cmd` use `dotnet-upgrade` for automatic-upgrade artifacts, independently of Linux installation and migration packages.

## Containerization

Some plugins depend on Redis, RustFS, MySQL, PostgreSQL, Etcd, ClickHouse, or TDengine. This project therefore supports two equivalent _**P**odman_-based/_**D**ocker_-based local containerization modes. Both modes include the development host and core infrastructure services; Compose additionally defines ClickHouse and TDengine. Users may choose either mode based on their preferred tools and data-lifecycle requirements.

### Runtime Modes

Mode | Definition files | Management commands | Data lifecycle | Typical use
-----|------------------|---------------------|----------------|------------
K8s Pod | `zongsoft.pod-*.yaml` | `podman kube play/down` | Removing a Pod discards container data | Describe services with Kubernetes manifests and manage them as Pods
Podman + Docker Compose | `zongsoft.compose.yaml` | `podman compose` | Container data can be preserved or cleared | Describe services with the Compose model and manage individual services or the project

Both modes can be installed on the same machine, but do not use both modes to start the same service at the same time. They share Windows host ports, the `zongsoft-net` network, and some network aliases.

### Common Environment Setup

Install the Podman CLI from one of the following locations:

- https://podman.io
- https://github.com/containers/podman/releases

> 💡 On Windows, make sure [WSL 2](https://learn.microsoft.com/windows/wsl/install) is installed.

#### Docker Compose Provider (Compose Mode Only)

Skip this section when using K8s Pod mode. For Compose mode, install a Docker Compose Provider as follows:

1. Download [Docker Compose for Windows x64](https://github.com/docker/compose/releases/download/v5.5.0/docker-compose-windows-x86_64.exe) from the [Docker Compose releases](https://github.com/docker/compose/releases/download) page;
2. Rename the downloaded file to `docker-compose.exe` and copy it to the Podman installation directory, for example `C:\Program Files\RedHat\Podman`;
3. Create an environment variable named `PODMAN_COMPOSE_PROVIDER` whose value is the full path to `docker-compose.exe`, for example `C:\Program Files\RedHat\Podman\docker-compose.exe`;
4. Verify the installation by running `podman compose version` in a terminal.

#### Network Mode

The `%USERPROFILE%` directory may contain a `.wslconfig` file that specifies the WSL network mode, for example:

```ini
[wsl2]
networkingMode=Mirrored
dnsTunneling=true
firewall=false
autoProxy=true
```

💡 **Note:** This configuration enables mirrored networking. In this mode, multiple container instances may be unable to communicate with one another, even when `.wslconfig` contains `hostAddressLoopback=true` and the container YAML specifies `hostNetwork: true`. NAT mode is a more reliable option for this setup. Use the following steps to reset WSL networking to NAT mode.

1. Shut down WSL:

```shell
wsl --shutdown
```

2. Delete `.wslconfig`:

	- Option 1: Enter `%USERPROFILE%` in the File Explorer address bar, enable display of hidden files if necessary, and delete `.wslconfig`.

	- Option 2: Run the following command in PowerShell on the Windows host:
		> ```shell
		> rm $env:USERPROFILE\.wslconfig -Force
		> ```

3. Reset the network settings.

> Run the following commands in PowerShell on the Windows host.<br />
> You may need to restart Windows afterward.

```shell
netsh winsock reset
netsh int ip reset
```

4. Check the network after restarting:

```shell
# Check the WSL network interface state
wsl ip addr show eth0

# Check whether a port is listening (Redis 6379 in this example)
wsl ss -tlnp | grep ':6379'
```

Expected results:

- The `eth0` interface should be `UP`;
- An `inet` address, usually in a `172.x.x.x` range, should be present.

#### Directory Mapping

For convenient development, host directories can be bind-mounted into the root of the Podman machine:

1. Enter the Podman machine and edit `/etc/fstab`:

	```shell
	sudo vi /etc/fstab
	```

2. Append entries such as:

	```plaintext
	/mnt/d/Automao  /Automao  none bind 0 0
	/mnt/d/Zongsoft /Zongsoft none bind 0 0
	```

3. Restart the Podman machine:

	```shell
	podman machine stop
	podman machine start
	```

#### Registry Mirrors

Containerizer builds and local `run` use explicitly configured image sources in `.containerized/.mirrors`. For example:

```ini
docker.io=docker.m.daocloud.io
mcr.microsoft.com=mcr.m.daocloud.io
quay.io=quay.m.daocloud.io
```

Separate multiple mirrors for one registry with semicolons; they are tried in order. The tool first reuses local images verified against the digest and architecture, then tries mirrors, then the original registry. Once resolved, the digest does not change during fallback. Default builds and `make` read this file from the final output directory; `run` reads it beside the selected archive; `plan` does not access registries. The file is not recorded in `.container` or delivery archives, and the tool does not modify global Podman/Docker configuration. Without rules, existing engine behavior is preserved. Image mirrors do not fix APT/DNF package feeds or broken proxy settings.

These public mirrors are explicitly selected for this directory; the tool neither embeds nor automatically enables them. Other endpoints use `host[:port][/prefix]`, without schemes, tags, digests or credentials. The local `.mirrors` includes all 11 registries in [DaoCloud's official list](https://github.com/DaoCloud/public-image-mirror). New entries use its recommended `m.daocloud.io/<source-registry>` prefix; the original three aliases are retained. `k8s.gcr.io` is a legacy entry and upstream marks `registry.ollama.ai` experimental.

For direct Podman, K8s Pod or Compose operations, configure global mirrors in the Podman machine manually if needed:

1. Enter the Podman machine:

	```shell
	podman machine ssh
	```

2. Edit the container registry configuration:

	```bash
	sudo vi /etc/containers/registries.conf
	```

	A representative configuration is shown below:

	```toml
	[[registry]]
	  location = "docker.io"
	[[registry.mirror]]
	  location = "docker.m.daocloud.io"

	[[registry]]
	  location = "mcr.microsoft.com"
	[[registry.mirror]]
	  location = "mcr.m.daocloud.io"

	[[registry]]
	  location = "quay.io"
	[[registry.mirror]]
	  location = "quay.m.daocloud.io"
	```

	Each `[[registry.mirror]]` belongs to its preceding `[[registry]]`. MCR needs its own registry entry and cannot be a Docker Hub mirror. Do not put `prefix` in mirror entries.

3. Exit and restart the Podman machine:

	```shell
	podman machine stop
	podman machine start
	```

#### Network Proxy

The following example uses v2rayN's mixed proxy port `10808`. Keep v2rayN running on Windows and enable connections from the LAN so the machine can reach the host proxy in NAT mode. If `/etc/environment` or `/etc/profile.d/proxy.sh` already contains proxy settings, update their ports as well; both HTTP and HTTPS proxy URLs can use `http://<Windows-host-address>:10808`.

1. Enter the Podman machine:

	```shell
	podman machine ssh
	```

2. Run the following commands inside the Podman machine to create a script that sets proxy environment variables and a systemd service that runs it when the machine starts:

```bash
cat > /usr/local/bin/set-podman-proxy-env.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

WIN_HOST="$(ip route | awk '/default/ {print $3; exit}')"
PROXY="socks5h://${WIN_HOST}:10808"
NO_PROXY_VALUE="localhost,127.0.0.1,::1"

systemctl set-environment \
	HTTP_PROXY="${PROXY}" \
	HTTPS_PROXY="${PROXY}" \
	ALL_PROXY="${PROXY}" \
	http_proxy="${PROXY}" \
	https_proxy="${PROXY}" \
	all_proxy="${PROXY}" \
	NO_PROXY="${NO_PROXY_VALUE}" \
	no_proxy="${NO_PROXY_VALUE}"
EOF

chmod +x /usr/local/bin/set-podman-proxy-env.sh

cat > /etc/systemd/system/podman-proxy-env.service <<'EOF'
[Unit]
Description=Set dynamic Windows proxy environment for Podman machine
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/set-podman-proxy-env.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now podman-proxy-env.service
```

### Database Initialization Prerequisites

Both modes run initialization SQL when a MySQL or PostgreSQL container is first created. Make sure the following repositories are located beside [hosting](https://github.com/Zongsoft/hosting):

- [administratives](https://github.com/Zongsoft/administratives)
- [discussions](https://github.com/Zongsoft/discussions)
- [framework](https://github.com/Zongsoft/framework)

If these repositories or their SQL files are missing, the database containers cannot complete initialization as expected.

### K8s Pod Mode

This mode describes services with Kubernetes Pod YAML and manages the Pods through Podman's `kube play` and `kube down` commands. It requires only the Podman CLI.

#### Pod Files

- [zongsoft.pod-host.yaml](./zongsoft.pod-host.yaml): Development host container with .NET SDK 10, `systemd`, `nginx`, and related tools.
	> This file contains network-proxy settings that should be adjusted for the local environment.
- [zongsoft.pod-etcd.yaml](./zongsoft.pod-etcd.yaml): Etcd distributed-configuration container.
- [zongsoft.pod-redis.yaml](./zongsoft.pod-redis.yaml): Redis distributed-cache container.
- [zongsoft.pod-rustfs.yaml](./zongsoft.pod-rustfs.yaml): RustFS distributed-file-system container.
- [zongsoft.pod-mysql.yaml](./zongsoft.pod-mysql.yaml): MySQL container and initialization scripts.
- [zongsoft.pod-postgres.yaml](./zongsoft.pod-postgres.yaml): PostgreSQL container and initialization scripts.

#### Start a Pod

Double-click `zongsoft.pod(start).cmd` in File Explorer, or run it in Command Prompt:

```cmd
zongsoft.pod(start).cmd
```

Enter the Pod to start when prompted:

- `host`: development host container;
- `etcd`: Etcd;
- `redis`: Redis;
- `rustfs`: RustFS;
- `mysql`: MySQL;
- `postgres`, `postgre`, or `postgresql`: PostgreSQL;
- `exit`: exit the script.

The script ensures that `zongsoft-net` exists, then creates or replaces the selected Pod with `podman kube play --network zongsoft-net --replace`.

Use the following command to inspect Pod and container status:

```shell
podman ps --all --pod
```

#### Stop a Pod

Double-click `zongsoft.pod(stop).cmd` in File Explorer, or run it in Command Prompt:

```cmd
zongsoft.pod(stop).cmd
```

Enter the Pod to stop when prompted. For an individual Pod, the script uses `podman kube down` to stop and remove it.

> ⚠️ Entering `*` runs `podman stop -a` followed by `podman rm -afv`. This affects every container in the current Podman environment, not only this project. Make sure no other containers need to be preserved before using it.

`kube down` removes the Pod and its containers, so data in the containers' writable layers is not preserved. It does not delete the host-mounted RustFS `.attachments` directory or the database initialization SQL source files.

#### Pod Network Addresses

All Pods join `zongsoft-net`. Use the Pod name and container port when one container connects to another Pod:

Pod name | Container name | Address inside the network | Windows address
---------|----------------|----------------------------|----------------
`zongsoft` | `zongsoft-host` | `zongsoft` | _No published port_
`zongsoft.distributed` | `zongsoft.distributed-etcd` | `zongsoft.distributed:2379` | `localhost:2379`
`zongsoft.caching` | `zongsoft.caching-redis` | `zongsoft.caching:6379` | `localhost:6379`
`zongsoft.data` | `zongsoft.data-mysql` | `zongsoft.data:3306` | `localhost:3306`
`zongsoft.data` | `zongsoft.data-postgres` | `zongsoft.data:5432` | `localhost:5432`
`zongsoft.io` | `zongsoft.io-rustfs` | `zongsoft.io:9000` | `localhost:9000`, `localhost:9001`

MySQL and PostgreSQL use the same Pod name, `zongsoft.data`, so choose one database in this mode rather than starting both at the same time.

For example, connect to RustFS and Redis from the development host container:

```shell
podman exec --interactive --tty zongsoft-host bash
curl -L -A "Mozilla/5.0(Linux; x64)" http://zongsoft.io:9001
redis-cli -h zongsoft.caching -p 6379
zongsoft.caching:6379> auth xxxxxx
OK
```

#### Common Pod Commands

```shell
# View logs
podman logs zongsoft-host
podman logs zongsoft.data-mysql
podman logs zongsoft.data-postgres
podman logs zongsoft.caching-redis

# Enter containers
podman exec --interactive --tty zongsoft-host bash
podman exec --interactive --tty zongsoft.data-mysql bash
podman exec --interactive --tty zongsoft.data-postgres bash
podman exec --interactive --tty zongsoft.caching-redis bash

# Start Pods directly without the script
podman network exists zongsoft-net || podman network create zongsoft-net
podman kube play --network zongsoft-net --replace .\zongsoft.pod-redis.yaml
podman kube play --network zongsoft-net --replace .\zongsoft.pod-mysql.yaml
podman kube play --network zongsoft-net --replace .\zongsoft.pod-postgres.yaml

# Stop and remove Pods directly without the script
podman kube down .\zongsoft.pod-host.yaml
podman kube down .\zongsoft.pod-redis.yaml
podman kube down .\zongsoft.pod-mysql.yaml
podman kube down .\zongsoft.pod-postgres.yaml

# The following commands affect every container in the current Podman environment
podman stop -a
podman rm -afv

# Remove the local RustFS image
podman rmi rustfs:latest
```

### Podman + Docker Compose Mode

This mode describes all services in [zongsoft.compose.yaml](./zongsoft.compose.yaml) and invokes a Docker Compose Provider through `podman compose`. It supports per-service startup, selectable data-retention behavior, and project-level management.

#### Compose Services

Service | Purpose
--------|--------
`host` | Development host container with .NET SDK 10, `systemd`, `nginx`, and related tools
`etcd` | Etcd distributed-configuration service
`redis` | Redis distributed-cache service
`mysql` | MySQL database and initialization scripts
`postgres` | PostgreSQL database and initialization scripts
`clickhouse` | ClickHouse analytical database with a `zongsoft` database and `program` user
`tdengine` | TDengine time-series database
`rustfs` | RustFS distributed-file-system service

Compose generates container names. Use stable service names for routine operations instead of depending on specific container names.

#### Start Compose Services

Double-click `zongsoft.compose(start).cmd` in File Explorer, or pass a service name directly:

```cmd
zongsoft.compose(start).cmd redis
zongsoft.compose(start).cmd mysql
zongsoft.compose(start).cmd clickhouse
zongsoft.compose(start).cmd tdengine
zongsoft.compose(start).cmd "*"
```

The script accepts `host`, `etcd`, `redis`, `mysql`, `postgres`, `clickhouse`, `tdengine`, `rustfs`, and `*`. An asterisk starts every service defined in `zongsoft.compose.yaml`.

The startup script checks Podman, the Docker Compose Provider, and the Podman machine, then idempotently creates the external shared network `zongsoft-net`.

Use the following command to inspect services in this project:

```shell
podman compose --file zongsoft.compose.yaml --project-name zongsoft ps --all
```

#### Stop Compose Services

The stop script supports both data-preserving and data-clearing modes:

```cmd
# Default: stop containers and preserve writable layers and anonymous volumes
zongsoft.compose(stop).cmd mysql
zongsoft.compose(stop).cmd mysql --keep

# Stop and remove the container and anonymous volumes, clearing container data
zongsoft.compose(stop).cmd mysql --clean

# Clear all Compose containers and anonymous volumes in this project
zongsoft.compose(stop).cmd "*" --clean
```

When launched interactively, the script asks whether to remove the container and clear its data.

- `--keep` uses `podman compose stop`, allowing a subsequent start to reuse the same container data;
- `--clean` uses `podman compose rm --stop --force --volumes` for an individual service;
- `* --clean` uses `podman compose down --remove-orphans --volumes`;
- Neither behavior deletes the external shared network `zongsoft-net`;
- `--clean` does not delete the host-mounted RustFS `.attachments` directory or the database initialization SQL source files.

#### Compose Network Addresses

All Compose services join `zongsoft-net` and can reach one another by service name or network alias:

Service | Address inside the network | Windows address
--------|----------------------------|----------------
`host` | `host` or `zongsoft` | _No published port_
`etcd` | `etcd:2379` or `zongsoft.distributed:2379` | `localhost:2379`
`redis` | `redis:6379` or `zongsoft.caching:6379` | `localhost:6379`
`mysql` | `mysql:3306` or `zongsoft.data.mysql:3306` | `localhost:3306`
`postgres` | `postgres:5432` or `zongsoft.data.postgres:5432` | `localhost:5432`
`clickhouse` | `clickhouse:8123` or `zongsoft.data.clickhouse:8123` | `localhost:8123`
`tdengine` | `tdengine:6030`/`tdengine:6041` or `zongsoft.data.tdengine` | `localhost:6030`, `localhost:6041`
`rustfs` | `rustfs:9000` or `zongsoft.io:9000` | `localhost:9000`, `localhost:9001`

MySQL and PostgreSQL use different service names and network aliases in this mode and can run at the same time.

ClickHouse creates the `zongsoft` database and `program` user on first initialization; create application tables separately. TDengine starts with its default `root` account and does not create the `zongsoft` database or `program` account configured in `web/default/Zongsoft.Hosting.Web.option`; provision both before using that connection. For a Windows native TDengine client on port 6030, `tdengine` must resolve to the container endpoint; the HTTP/WebSocket interface on port 6041 avoids that native-client endpoint requirement.

Containers access the Windows host through `host.containers.internal`. For example, if a Windows service listens on port `8080`, use the following address inside a container:

```text
http://host.containers.internal:8080
```

The `host` service connects directly by default. Set `ZONGSOFT_HTTP_PROXY` and `ZONGSOFT_HTTPS_PROXY` when a network proxy is required.

#### Common Compose Commands

```shell
# View logs
podman compose --file zongsoft.compose.yaml --project-name zongsoft logs host
podman compose --file zongsoft.compose.yaml --project-name zongsoft logs mysql
podman compose --file zongsoft.compose.yaml --project-name zongsoft logs postgres
podman compose --file zongsoft.compose.yaml --project-name zongsoft logs clickhouse
podman compose --file zongsoft.compose.yaml --project-name zongsoft logs tdengine
podman compose --file zongsoft.compose.yaml --project-name zongsoft logs redis

# Enter containers
podman compose --file zongsoft.compose.yaml --project-name zongsoft exec host bash
podman compose --file zongsoft.compose.yaml --project-name zongsoft exec mysql bash
podman compose --file zongsoft.compose.yaml --project-name zongsoft exec postgres bash
podman compose --file zongsoft.compose.yaml --project-name zongsoft exec redis bash

# Start individual services directly
podman network exists zongsoft-net || podman network create zongsoft-net
podman compose --file zongsoft.compose.yaml --project-name zongsoft up --detach redis
podman compose --file zongsoft.compose.yaml --project-name zongsoft up --detach mysql
podman compose --file zongsoft.compose.yaml --project-name zongsoft up --detach postgres
podman compose --file zongsoft.compose.yaml --project-name zongsoft up --detach clickhouse
podman compose --file zongsoft.compose.yaml --project-name zongsoft up --detach tdengine

# Stop services and preserve data
podman compose --file zongsoft.compose.yaml --project-name zongsoft stop redis mysql postgres

# Remove project containers while preserving anonymous volumes and the shared network
podman compose --file zongsoft.compose.yaml --project-name zongsoft down

# Remove project containers and anonymous volumes while preserving the shared network
podman compose --file zongsoft.compose.yaml --project-name zongsoft down --volumes
```

### Notes Common to Both Modes

#### Switching Between Modes

Both modes share `zongsoft-net`, Windows host ports, and some network aliases. Do not start the same service in both modes at the same time, or port and network-name conflicts will occur.

Before switching modes, stop the relevant services with the script for the currently active mode:

- K8s Pod to Compose: run `zongsoft.pod(stop).cmd` and stop the relevant Pod;
- Compose to K8s Pod: run `zongsoft.compose(stop).cmd <service> --clean` and remove the relevant Compose container.

#### Communication Between Windows and Containers

- Windows accesses infrastructure services through `localhost` and the corresponding published port;
- Containers access Windows through `host.containers.internal`;
- Containers access one another through the Pod names, service names, or network aliases documented for the selected mode;
- Do not hard-code container IP addresses because they can change when containers are recreated.

#### Startup Readiness

- On its first start, the `host` container installs and initializes tools such as `systemd` and `nginx`, so it may need additional time after the container reports that it is running;
- On their first start, MySQL and PostgreSQL execute schema and data initialization SQL. Wait for initialization to complete before connecting;
- Use the log commands for the selected mode to monitor initialization progress.

#### Default Development Credentials

Service | User name or access key | Password or secret key
--------|-------------------------|-----------------------
Redis | _No user name_ | `xxxxxx`
MySQL | `program` | `xxxxxx`
MySQL | `root` | `xxxxxx`
PostgreSQL | `program` | `xxxxxx`
ClickHouse | `program` | `xxxxxx`
TDengine | `root` | `taosdata`
RustFS | `rustfsadmin` | `rustfsadmin`

These credentials are intended only for local development. In Compose mode, override the defaults with the `ZONGSOFT_REDIS_PASSWORD`, `ZONGSOFT_MYSQL_PASSWORD`, `ZONGSOFT_MYSQL_ROOT_PASSWORD`, `ZONGSOFT_POSTGRES_PASSWORD`, `ZONGSOFT_CLICKHOUSE_PASSWORD`, `ZONGSOFT_TDENGINE_ROOT_PASSWORD`, `ZONGSOFT_RUSTFS_ACCESS_KEY`, and `ZONGSOFT_RUSTFS_SECRET_KEY` environment variables.
When installing a migration package, keep the MySQL root password aligned with `[mysql] root_password` in `.env`.
