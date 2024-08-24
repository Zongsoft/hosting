using System;

using Microsoft.Extensions.Hosting;

namespace Zongsoft.Hosting.Daemon
{
	internal class Program
	{
		static void Main(string[] args)
		{
			Zongsoft.Plugins.Hosting.Application
				.Daemon(args)
				.Run();
		}
	}
}
