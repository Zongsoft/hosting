using System;

using Microsoft.Extensions.Hosting;

namespace Zongsoft.Hosting.Terminal;

internal class Program
{
	static void Main(string[] args)
	{
		Zongsoft.Plugins.Hosting.Application
			.Terminal("zongsoft.terminal", [.. args, "host=terminal", "site=daemon"])
			.Run();
	}
}
