using System;

using Microsoft.Extensions.Hosting;

namespace Zongsoft.Hosting.Terminal;

internal class Program
{
	static void Main(string[] args)
	{
		Velopack.VelopackApp.Build().Run();

		Zongsoft.Plugins.Hosting.Application
			.Terminal([.. args, "host=terminal", "site=daemon"])
			.Run();
	}
}
