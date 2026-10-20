using System;
using System.Threading.Tasks;

using Microsoft.Extensions.Hosting;

namespace Zongsoft.Hosting.Terminal;

internal class Program
{
	static async Task Main(string[] args)
	{
		var host = await Zongsoft.Plugins.Hosting.Application.TerminalAsync(
			"zongsoft.terminal", [.. args, "host=terminal", "site=daemon"]);

		await host.RunAsync();
	}
}
