using System;
using System.Threading;
using System.Threading.Tasks;

using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Builder;

namespace Zongsoft.Hosting.Web;

internal class Program
{
	static void Main(string[] args)
	{
		var app = Zongsoft.Web.Application.Web(args);

		//如果要启用私有部署模式则打开下行代码注释
		//app.Configuration["Deployment"] = "private";

		app.Map("/", ctx => { ctx.Response.Redirect("/Application"); return Task.CompletedTask; });
		app.Run();
	}
}
