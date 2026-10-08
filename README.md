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

A host application is responsible only for initializing the runtime environment. It serves as a plugin container and contains no concrete business implementation itself. Deployment means placing the required plugins and their related files, such as configuration and certificates, in the appropriate subdirectories under `plugins`.

Run the interactive Windows script `deploy.cmd` from the target host directory to build, apply the deployment files (`*.deploy`), and then choose whether to create an installation package. This repository supplies scripts for `daemon`, `terminal`, and `web/default`.

> The deployment scripts use **Z**ongsoft.**T**ools.**D**eployer. For usage instructions, see the documentation in its open-source repository:
> - English: [https://github.com/Zongsoft/tools/blob/main/deployer/README.md](https://github.com/Zongsoft/tools/blob/main/deployer/README.md)
> - Chinese: [https://github.com/Zongsoft/tools/blob/main/deployer/README.zh-Hans.md](https://github.com/Zongsoft/tools/blob/main/deployer/README.zh-Hans.md)

The `deploy.cmd` scripts in `web/default`, `daemon`, and `terminal` use `--overwrite:newest`, `--prerelease:true`, and `--verbosity:quiet`, allowing plugin dependencies that are available only as prerelease packages. Missing optional files are skipped with warnings. A failed build or deployment stops the script before packaging. If daemon fails to build, deploy, or package, it displays the failed stage and exit code, then waits for a key before exiting. Daemon and terminal plugins are deployed to `bin/<configuration>/<target-framework>/plugins`.

The host `deploy.cmd` and `pack.cmd` scripts use their own directory as the working directory, so they can also be called from another directory. Build, deployment, Web plugin cleanup and packaging paths remain relative to that host. On completion, failure or skipped packaging, the scripts restore the caller's directory and environment.

The deployment and packaging tool calls in `deploy.cmd` and `pack.cmd` omit `--framework`, so the tools resolve `framework` from their merged Variables. Set `framework` in the hosting root's `.env` to share it across hosts. Neither script prompts for a framework. All host `deploy.cmd` scripts also omit `--framework` from the Cake call, using the default in each host's `build.cake`. Cake does not read `.env`; keep its build target consistent with the framework used for deployment and packaging. See “Installation and migration packages” below for setup.

Each host uses the same payload and service definitions in `deploy.cmd` and `pack.cmd`. Packaging after deployment inherits the build configuration and architecture; the standalone `pack.cmd` asks for these separately and does not build or deploy plugins. Daemon explicitly sets `--daemon:zongsoft.daemon` to generate its service through the packager; terminal keeps `--daemon:disabled`. Their application names remain `zongsoft.daemon` and `zongsoft.terminal`, matching their respective `.version` files and runtime application names. Their `--title` values are `Zongsoft.Daemon` and `Zongsoft.Terminal`. Web generates its Nginx configuration with `--web:nginx`.
All hosts pass `Environment` and `DOTNET_ENVIRONMENT` using the selected environment value and list both in `--daemon-environments`; Web also passes and lists `ASPNETCORE_ENVIRONMENT`. Daemon and Web services receive these variables. The standalone terminal `pack.cmd` also asks for the environment, retaining the process `Environment` value on empty input or otherwise defaulting to `development`.

### Local Plugin Verification and Startup Troubleshooting

Features come from plugins and configuration; the host Program need not reference every implementation. Business code should depend on Core/shared module interfaces and obtain implementations through `ApplicationContext.Current.Services`, the application's own `Module.Current.Services`, or a configured provider. See [Core service lookup](https://github.com/Zongsoft/framework/blob/main/Zongsoft.Core/README.md) and the [plugin deployment guide](https://github.com/Zongsoft/framework/blob/main/Zongsoft.Plugins/README.md).

1. Prepare an isolated deployment. Review its manifests and startup workers, including only required plugins and test configuration.
2. Build or publish a compatible launcher. When copying debug output, retain `*.deps.json`, `*.runtimeconfig.json`, dependency DLLs, `runtimes/`, and resource directories, not just the main DLL.
3. Run from the deployment directory. The default content root depends on the working directory; invoking an absolute DLL path from elsewhere does not change it and may report a missing `plugins` directory.
4. A Windows terminal host needs valid console handles. Use an interactive terminal or PTY/ConPTY; a console-less pipe can fail with an invalid-handle error. Use a daemon/Web launcher for unattended hosting.
5. Verify the plugin list, configuration, and service lookup before connecting to authorized local infrastructure. Record expected and actual results without logging credentials or business data.
6. Exit with `exit -yes`. Clean up only this verification's data and resources you started.

🚨 Successful plugin loading does not prove runtime dependencies are complete. An older host Core can cause assembly-loading errors during service scanning; missing `runtimes` assets can break platform dependencies; transitive dependencies can overwrite a shared SDK and cause missing-method errors on first use. Preserve the first error and inspect **final deployed files**, not just project references or build success.

The terminal entry point appends `host=terminal` and `site=daemon`. These affect runtime option selection; the deployer's `--site` operates at a different stage.

For a minimal HTTP check, follow the [decoupled Web plugin example](https://github.com/Zongsoft/framework/blob/main/Zongsoft.Plugins.Web/README.md). Controller discovery does not create a missing route template: the default host uses `MapControllers()`, so verify a real response instead of just the plugin list. In manual native-plugin deployments, retaining `runtimes/` can be necessary but not sufficient; verify the actual native search layout. A Windows x64 SQLite probe required its matching `e_sqlite3.dll` beside the managed SQLite components.

### Deployment Files

Configuration files are usually specific to a product, project, deployment platform (such as standalone, intranet, private cloud, or public cloud), and environment (such as development, testing, or production). Store these context-specific files separately under `/hosting/.deploy` for centralized management and maintenance.

> For more deployment-item examples, see the `.deploy` files in the host application directories.

#### Configuration Files

Configuration files should be named according to the environment to which their contents apply, with the environment name appended to the base file name. The following examples use configuration files from the **Zongsoft.Security** plugin:

- `Zongsoft.Security.option`
	> Environment-independent configuration whose values act as defaults for environment-specific files.
-----
- `Zongsoft.Security.test.option`
	> Configuration for the **test environment**. For example, its database connection string may point to a **test database** through an **intranet address**.
- `Zongsoft.Security.production.option`
	> Configuration for the **production environment**. For example, its database connection string may point to a **production database** through an **intranet address**.
- `Zongsoft.Security.development.option`
	> Configuration for the **development environment**. For example, its database connection string may point to a **development database** through an **intranet address**.
-----
- `Zongsoft.Security.test-debug.option`
	> Debug configuration for the **test environment**. For example, its database connection string may point to a **test database** through a **public address**.
- `Zongsoft.Security.production-debug.option`
	> Debug configuration for the **production environment**. For example, its database connection string may point to a **production database** through a **public address**.
- `Zongsoft.Security.development-debug.option`
	> Debug configuration for the **development environment**. For example, its database connection string may point to a **development database** through a **public address**.

### Directory Structure

The `.deploy` directory under `hosting` is the root directory for deployment-related resources. Its structure is as follows:

- `certificates`: optional certificate files
	> Certificates that are independent of a deployment platform.

- `{scheme}`: deployment scheme
	- `options`: configuration files
	- `migration`: migration inputs
		> `<version>/*.migration` references SQL files or declares Amazon S3 buckets; `.ini` files in the same directory or an ancestor supply migration connection parameters.

Add `certificates` directories as needed; the current default scheme contains `options/` and `migration/`. The hosting root's `.env` supplies shared tool variables, `.migration/` holds generated migration archives and launchers, and each host's `.packages/` holds installation packages.

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

Tools merge defaults, process environment variables, `.env` files from the filesystem root down to the source directory (working directory for migrator), and explicit command options, in that order. An omitted, null, or empty `framework` option uses Variables; whitespace alone is not treated as empty. Section entries such as `[mysql] root_password` become variables such as `mysql_root_password` for migration `.ini` references.

Prepare deployment environment variables in the current PowerShell window, then enter the target host directory:

```powershell
$env:Environment = 'development'
Set-Location D:/Zongsoft/hosting/daemon
.\deploy.cmd
```

The three deploy.cmd scripts still require the process Environment variable because their environment prompt stores input in value. Standalone pack.cmd now accepts environment directly and retains the process `Environment` value on empty input or otherwise defaults to `development`.

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


The last two lines are alternative ways to create a new release. A named subcommand followed by inputs/options runs without the new-delivery prompts; a single `.container` argument remains shorthand for `make`. Interactive `make` lists the `*.container` files directly inside `.containerized`, sorted by filename, followed by a manual-path option. Only that last option prompts for a path; when no files are found, it is the only choice. After selecting a manifest, you can enter an optional new release version. This menu also appears for `containerize.cmd make` without a path. Saved selections are retained; only version and engine selections can override a manifest in the interactive script. Source is fixed to the hosting directory and output to `.containerized`. Both scripts restore the calling directory/environment.

After a complete build, plan or make, the script displays an explicit success message or a failure message with the original tool exit code. Tool diagnostics remain visible. Both successful and failed operations wait for a key before exiting, so the command window stays open for inspection.

The script groups operation selection, delivery settings, inputs and execution results into labeled sections. Titles are bold cyan, helper/key instructions are gray, and the selected menu row has a highlighted background. Success, warnings and errors use green, yellow and red, with explicit status markers. Default/key instructions appear below each text input, aligned with the field label; type directly after the field name and colon (for example, `Application name: `). Press Enter to continue, with one blank row between consecutive inputs. Redirected output stays plain text; set `NO_COLOR` to disable script colors in a console. Arrow-key navigation, Esc/back, literal paths, direct arguments and tool exit codes retain their behavior.

When creating a delivery, the migration directory menu offers three choices: no migrations (default), `.migration` under the hosting directory, or manual entry. Empty or whitespace-only manual input also disables migrations; press Esc during manual entry to return to this menu.

New selections default to application name `zongsoft`, Debian 13, x64, automatic engine selection and offline bootstrap/images. An empty release version uses a date version; existing delivery archives are never overwritten. Prepare installation packages with deploy.cmd/pack.cmd and migrations with migrate.cmd first; containerize.cmd does not compile hosts or generate migrations. Component inputs include template IDs such as redis, package files, and directories such as daemon or web/default.

The image delivery option is `--imaging:online|offline`, with matching root/service `imaging` entries in `.container`; `bootstrap` still controls engine dependencies independently.

`.containerized/.settings` replaces the infrastructure `.version` list (application package `.version` files are unrelated). It preserves the existing image tags and references root `.env` variables for Redis, MySQL and RustFS secrets. Redis defaults to persistent storage and both RDB/AOF; edit a planned manifest to use `storage=temporary;persistence=none` for a particular test build. No password values are copied into shared settings. Other services' required parameters still need to be supplied when selected.

For packaged Web applications, Nginx listeners come from the package's `.web/nginx/.bindings`. With no port override, every supported listener is published, including 80 and 8080 when declared. Nginx settings use `settings=port=80:18080,443:none`: container 80 prefers host 18080, while 443 stays internal. A saved `.container` must contain this syntax directly; `port=127.0.0.1:80` is invalid for Nginx. Changing `.settings` does not change a saved manifest.

`plan` creates only `name[-tag]@version-architecture.container`, without using an engine or resolving image digests. Missing required parameters produce magenta warnings and a successful draft; fix them before `make`. `make` ignores subsequent changes to shared `.settings`, resolves variables, and publishes the completed manifest plus its `.tar.gz` only after success. Failed builds retain the draft. The archive includes English/Chinese READMEs and an identical completed manifest. Shared settings can be version controlled; generated archives remain ignored.

Interactive run lists the hosting root's `.containerized/*.tar.gz`, ending with manual path entry. Esc returns from manual input to file selection, then to the operation menu. `containerize.cmd run FILE.tar.gz [--engine:podman]` runs directly without build options or a version prompt. The tool prints actual local Web/TCP mappings and interface addresses whose LAN reachability has not been probed; keep the window open and use Ctrl+C to remove the environment and test data. First base preparation may need Internet access. Web publication requests all IPv4 interfaces from the engine; LAN access also depends on host/VM forwarding and firewall rules. Web probes preserve Host/SNI and certificate validation while connecting to the actual local mapping. See the maker's run documentation for verified platforms and failure inspection.

The build branches do not perform onsite installation or service control. The run branch installs inside a disposable local verification container. Runtime health checks validate process/listener liveness, not business readiness; see the maker's platform acceptance matrix before selecting a deployment combination.

### Package after deployment or package existing files

Run `deploy.cmd` from the target host directory and select the scheme (default `default`), environment, remote debugging, platform, and architecture. Remote debugging defaults to `on`, selecting Debug/Windows; `off` selects Release/Linux, with a subsequent prompt to change the platform. For Linux installation verification, select `off`, `linux`, and the matching architecture. A failed build or deployment stops the sequence. Web deployment also clears the site's `plugins/` directory first.

After deployment, enter `tar`, `deb`, or `rpm` at the format prompt to create an installation package. Enter `exit` or `quit` to skip packaging; this branch currently returns exit code `1` and does not trigger daemon's failure pause. Running `pack.cmd` directly packages existing files only:

```powershell
Set-Location D:/Zongsoft/hosting/web/default
.\pack.cmd
```

| Standalone `pack.cmd` parameter | Default or behavior |
| --- | --- |
| Format | `tar`; also supports `deb` and `rpm`. All three set the target platform to Linux |
| Edition, version | May be empty; resolved from the host source directory's direct `.edition` (preferred) or `.version`. Edition is separate from the Debug/Release build configuration |
| Environment | See above; passed as `Environment` and `DOTNET_ENVIRONMENT`, plus `ASPNETCORE_ENVIRONMENT` for Web |
| Build configuration | `Release`; `Debug` is supported and must match existing output |
| Architecture | `x64`; `arm64` is supported and must match the application and migration executor |
| Scheme | Only the standalone Web script asks; defaults to `default`. It packages existing files without reapplying the scheme |
| Migration name or path | Empty skips integration; for example `zongsoft`. See below |

| Host | Application name / service | Payload and default installation directory |
| --- | --- | --- |
| daemon | `zongsoft.daemon` / `zongsoft.daemon.service` | Flattened `bin/$(compilation)/$(framework)`; `/opt/zongsoft/daemon` |
| terminal | `zongsoft.terminal` / service disabled | The same flattened build directory; `/opt/zongsoft/terminal` |
| web/default | `Zongsoft.Hosting.Web` / `zongsoft.web.service` | MIME files, configuration, wwwroot, plugins, and the flattened build directory; `/opt/zongsoft/web`, application listener `127.0.0.1:8069` |

All scripts exclude `logs/`; Web additionally excludes `*.staticwebassets.*` in the build directory. The `:~` alias places directory contents at the installation root without retaining the original `bin/...` hierarchy. See the [Web README](web/README.md#packaging-the-default-site) for its service and Nginx configuration. Terminal disables systemd services, so `--daemon-environments` does not set process variables for an interactively launched terminal.

Output goes to the selected host's `.packages/`, for example `zongsoft.daemon@1.0.0-x64.deb`; a nonempty Edition is appended to the package name. Tar produces a matching `.tar.gz` archive and `.sh` installation entry; keep both together. Deb/rpm each produce one package file. These scripts do not enable `--overwrite`, so an existing output of the same name causes generation to fail.

After successful packaging, an existing source `.edition` and `.version` are both rewritten, creating `.version` if absent. If only `.version` exists, only it is updated; if neither exists, both are created together. The installation payload always contains `.version` for the final identity and excludes the source directory's direct `.edition`. Installing or upgrading an installation package is a separate action; these scripts do not install it.

### Create a migration package before installation-package integration

Run `migrate.cmd` from the hosting root. Enter the migration name (default `zongsoft`), optional Edition, required version number/version file/directory, platform (default `linux`), architecture (default `x64`), and scheme (default `default`). Empty input at the first path prompt selects `.deploy/$(scheme)/migration/$(version)/*.migration`; alternatively, supply files one by one and then finish with empty input. A filename without directory separators resolves under that scheme/version directory; relative paths with directories resolve from the hosting root. Bare `*` is rejected; use `*.migration`.

Migration prompts use the same style as `containerize.cmd`: bold cyan headings, cyan fields, gray hints, and green/yellow/red `[OK]`/`[WARN]`/`[ERROR]` markers. Hints appear below each text input, aligned with the field label; type directly after the field name and colon, then press Enter to continue. Consecutive input fields are separated by one blank row. Redirected output remains plain text; `NO_COLOR` disables script colors. On success the script exits normally; on failure it keeps tool diagnostics visible, waits for a key and returns the original exit code.

For example, create the default Linux x64 migration package from the hosting root:

```powershell
dotnet-migrate --name:zongsoft --version:1.0.0 --platform:linux --architecture:x64 --scheme:default --output:.migration '.deploy/$(scheme)/migration/$(version)/*.migration'
```

This produces `.migration/zongsoft(migrate)@1.0.0_linux-x64.tar.gz` and its matching `.sh`. Windows x64 produces a `win-x64` archive and `.cmd`; Linux also supports arm64. Creation parses inputs, expands variables, and packages files without connecting to or changing databases/buckets. The script has no overwrite switch; to recreate an existing output, invoke the tool directly with explicit `--overwrite`.

The default version directory contains MySQL and Amazon S3 inputs; connection parameters are in `.deploy/default/migration/*.ini`. The archive root contains `migration.json`, `id`, the internal launcher, the native executor, and its dependencies. SQL files are under `.artifacts/mysql/`, without a `.migration` wrapper.

Next, enter `zongsoft` at the migration prompt in the host's `deploy.cmd` or `pack.cmd`. The packager searches the host source directory and its ancestors, including each direct `.migration/`, for a matching pair using the final Edition, version, and RID. Both files must come from the same location and match completely. An input with a directory checks only that directory, for example `../.migration/zongsoft` from daemon or `../../.migration/zongsoft` from Web. This option does not create migration artifacts.

The installation package carries the archive and external launcher unchanged under its installation root's `.migration/`. At execution, the launcher extracts to a separate temporary directory, with the plan and executor at its root, and cleans it afterward. Installation runs `apply` with state under `/var/lib/<package-name>/packager`; a failed migration prevents service startup. Before starting, systemd runs `check` against the local completion marker. Terminal also runs an integrated migration at installation despite disabling daemon support. SQL scripts themselves must make repeated execution safe.

### Package metadata and dependencies

The current hosting scripts have no separate prompts for homepage, manufacturer, maintainer, or dependencies. Set root-level `homepage`, `manufacturer`, `maintainer`, and `dependencies` variables in an applicable `.env`, or invoke `dotnet-pack` directly with these options. The homepage option is `--homepage`; `--manufacturer` and `--maintainer` both default to `Zongsoft`. A null or empty manufacturer also uses the default; whitespace is preserved.

Deb/rpm share the `--dependencies` syntax `name[:range]`, for example `--dependencies:"aspnetcore-runtime-10.0:[10.0,11.0)"` or `--dependencies:"aspnetcore-runtime-10.0:[10.0)"`. Commas/semicolons outside a range mean all groups are required; `|` means alternatives. The packager converts this to Debian `Depends` and RPM `Requires` without mapping distribution package names. RPM alternatives require 4.13+, and bounded ranges require 4.14+. See the packager's bilingual README for complete rules.

`upgrade.pack.cmd` / `upgrade.publish.cmd` use `dotnet-upgrade` to create and publish automatic-upgrade artifacts, independently of Linux installation and migration packages. Upgrade packaging still prompts for framework; the framework prompt convention for `deploy.cmd` / `pack.cmd` does not apply to it.

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

ClickHouse creates the `zongsoft` database and `program` user on first initialization; create application tables separately. TDengine starts with its default `root` account and does not create the `zongsoft` database or `program` account configured in `web/default/web.option`; provision both before using that connection. For a Windows native TDengine client on port 6030, `tdengine` must resolve to the container endpoint; the HTTP/WebSocket interface on port 6041 avoids that native-client endpoint requirement.

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
