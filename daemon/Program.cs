using System;
using System.Threading.Tasks;

using Microsoft.Extensions.Hosting;

namespace Zongsoft.Hosting.Daemon;

internal class Program
{
	static async Task Main(string[] args)
	{
		var host = await Zongsoft.Plugins.Hosting.Application.DaemonAsync(
			"zongsoft.daemon", [.. args, "host=daemon", "site=daemon"], builder =>
			{
				#if WINDOWS
				builder.Services.AddWindowsService(options => options.ServiceName = builder.Environment.ApplicationName);
				#elif LINUX
				builder.Services.AddSystemd();
				#endif
			});

		await host.RunAsync();
	}
}
