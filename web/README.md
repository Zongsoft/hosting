[English](README.md) | [简体中文](README.zh-Hans.md)

## Directory Structure

Web hosts are normally divided by application site. A SaaS application commonly provides:

- `administration`: interactive site for platform administrators.
- `business`: interactive site for tenant employees.
- `customer`: interactive site for tenant customers.
- `gateway`: non-interactive callbacks and system integration.
- `iot`: non-interactive device ingress.

This repository currently provides the `default` site. Additional site directories can follow the same structure, but their build and deployment scripts must use the correct `site` parameter.

## Services

### HttpYac

Install the [HttpYac extension for Visual Studio Code](https://marketplace.visualstudio.com/items?itemName=anweber.vscode-httpyac) and add the following representative settings to `settings.json`. Adjust every hostname and port for the selected environment.

```json
{
	"httpyac.environmentPickMany": false,
	"httpyac.environmentUseSameForAllFiles": true,
	"httpyac.environmentShowStatusBarItem": true,
	"httpyac.environmentStoreSelectedOnStart": false,
	"httpyac.requestDefaultHeaders": {
		"X-Json-Behaviors": "casing:camel;ignores:null,empty",
		"User-Agent": "httpyac"
	},
	"httpyac.codelens": {
		"send": true,
		"clearHistory": true,
		"saveResponse": true,
		"sendSelected": true,
		"showResponse": true,
		"showResponseHeaders": true,
		"showVariables": true,
		"pickEnvironment": true,
		"resetEnvironment": true,
		"validateVariables": true
	},
	"httpyac.environmentVariables": {
		"$shared": {
			"scenario": "api"
		},
		"local": {
			"environmentName": "local",
			"host": "127.0.0.1",
			"port": "8069",
			"url": "{{host}}:{{port}}"
		},
		"production.a": {
			"environmentName": "production.a",
			"host": "api.a.zongsoft.com",
			"port": "80",
			"url": "{{host}}:{{port}}"
		},
		"production.b": {
			"environmentName": "production.b",
			"host": "api.b.zongsoft.com",
			"port": "80",
			"url": "{{host}}:{{port}}"
		},
		"production.c": {
			"environmentName": "production.c",
			"host": "api.c.zongsoft.com",
			"port": "80",
			"url": "{{host}}:{{port}}"
		},
		"production.iot": {
			"environmentName": "production.iot",
			"host": "api.iot.zongsoft.com",
			"port": "80",
			"url": "{{host}}:{{port}}"
		},
		"production.gateway": {
			"environmentName": "production.gateway",
			"host": "api.gateway.zongsoft.com",
			"port": "80",
			"url": "{{host}}:{{port}}"
		},
		"development.a": {
			"environmentName": "development.a",
			"host": "api.dev.a.zongsoft.com",
			"port": "80",
			"url": "{{host}}:{{port}}"
		},
		"development.b": {
			"environmentName": "development.b",
			"host": "api.dev.b.zongsoft.com",
			"port": "80",
			"url": "{{host}}:{{port}}"
		},
		"development.c": {
			"environmentName": "development.c",
			"host": "api.dev.c.zongsoft.com",
			"port": "80",
			"url": "{{host}}:{{port}}"
		},
		"development.iot": {
			"environmentName": "development.iot",
			"host": "api.dev.iot.zongsoft.com",
			"port": "80",
			"url": "{{host}}:{{port}}"
		},
		"development.gateway": {
			"environmentName": "development.gateway",
			"host": "api.dev.gateway.zongsoft.com",
			"port": "80",
			"url": "{{host}}:{{port}}"
		},
		"test.a": {
			"environmentName": "test.a",
			"host": "api.test.a.zongsoft.com",
			"port": "80",
			"url": "{{host}}:{{port}}"
		},
		"test.b": {
			"environmentName": "test.b",
			"host": "api.test.b.zongsoft.com",
			"port": "80",
			"url": "{{host}}:{{port}}"
		},
		"test.c": {
			"environmentName": "test.c",
			"host": "api.test.c.zongsoft.com",
			"port": "80",
			"url": "{{host}}:{{port}}"
		},
		"test.iot": {
			"environmentName": "test.iot",
			"host": "api.test.iot.zongsoft.com",
			"port": "80",
			"url": "{{host}}:{{port}}"
		},
		"test.gateway": {
			"environmentName": "test.gateway",
			"host": "api.test.gateway.zongsoft.com",
			"port": "80",
			"url": "{{host}}:{{port}}"
		}
	}
}
```

Keep HttpYac request files in `.http`. `application.http` covers application services and `authentication.http` is the authentication entry point. Organize site-specific requests under `.http/sites`.

Shared environment values belong in `httpyac.environmentVariables`. Select the target environment from the HttpYac status bar before sending requests. Authentication scripts store credentials back into the current environment, so every environment must define an `environmentName` matching its environment key.

See the [HttpYac documentation](https://httpyac.github.io) for syntax and configuration details.

## Deployment

See the parent [hosting deployment guide](../README.md).

## IIS Express Notes

### Site Bindings

IIS Express binds to `localhost` by default. To use an IP address or custom hostname, edit `.vs/config/applicationhost.config`, locate `system.applicationHost/sites/site[name=xxxx]/bindings`, and add a binding such as:

```xml
<binding protocol="http" bindingInformation="*:8069:127.0.0.1" />
```

Then run an elevated terminal and reserve the URL. The URL must end with `/`:

```shell
netsh http add urlacl url=http://*:8069/ user=everyone
netsh http show urlacl
```

### Request Limits

For large uploads, add a request limit under `system.webServer/security/requestFiltering` in `applicationhost.config`:

```xml
<requestLimits maxAllowedContentLength="524288000" />
```

If the host uses the legacy ASP.NET setting, keep the corresponding `Web.config` value aligned:

```xml
<system.web>
	<httpRuntime maxRequestLength="524288000" />
</system.web>
```

References:

- [netsh http commands](https://learn.microsoft.com/en-us/windows-server/networking/technologies/netsh/netsh-http)
- [Handling URL binding failures in IIS Express](https://learn.microsoft.com/en-us/iis/extensions/using-iis-express/handling-url-binding-failures-in-iis-express)
