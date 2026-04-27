using System;

using Microsoft.Extensions.Hosting;

namespace Zongsoft.Hosting.Daemon;

internal class Program
{
	static void Main(string[] args)
	{
		#if WINDOWS
		Console.WriteLine("Windows");
		#elif LINUX
		Console.WriteLine("Linux");
		#else
		Console.WriteLine("Other");
		#endif

		Zongsoft.Plugins.Hosting.Application
			.Daemon("zongsoft.daemon", [.. args, "host=daemon", "site=daemon", "daemon=zongsoft.daemon"])
			.Run();
	}
}
