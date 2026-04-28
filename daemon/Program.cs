using System;

using Microsoft.Extensions.Hosting;

namespace Zongsoft.Hosting.Daemon;

internal class Program
{
	static void Main(string[] args)
	{
#if WINDOWS
		Zongsoft.Plugins.Hosting.Application
			.Daemon("zongsoft.daemon", [.. args, "host=daemon", "site=daemon"], builder =>
			{
				builder.Services.AddWindowsService(options => options.ServiceName = builder.Environment.ApplicationName);
			}).Run();
#elif LINUX
		Zongsoft.Plugins.Hosting.Application
			.Daemon("zongsoft.daemon", [.. args, "host=daemon", "site=daemon"], builder =>
			{
				builder.Services.AddSystemd();
			}).Run();
#else
		Zongsoft.Plugins.Hosting.Application
			.Daemon("zongsoft.daemon", [.. args, "host=daemon", "site=daemon"])
			.Run();
#endif
	}
}
