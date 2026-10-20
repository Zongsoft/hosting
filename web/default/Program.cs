using System;
using System.Threading;
using System.Threading.Tasks;

using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Builder;

namespace Zongsoft.Hosting.Web;

internal class Program
{
	static async Task Main(string[] args)
	{
		var app = await Zongsoft.Web.Application.WebAsync([.. args, "host=web", "site=default", "daemon=zongsoft.web"]);

		//如果要启用私有部署模式则打开下行代码注释
		//app.Configuration["Deployment"] = "private";

		app.Map("/", ctx => { ctx.Response.Redirect("/Application"); return Task.CompletedTask; });
		await app.RunAsync();
	}
}
