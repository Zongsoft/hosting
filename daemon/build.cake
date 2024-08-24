var cloud = Argument("cloud", "aliyun");
var target = Argument("target", "default");
var edition = Argument("edition", "Debug");
var framework = Argument("framework", "net8.0");
var solutionFile  = "Zongsoft.Hosting.Daemon.sln";

Task("clean")
	.Description("清理解决方案")
	.Does(() =>
{
	DeleteFiles("*.nupkg");
	CleanDirectories("**/bin");
	CleanDirectories("**/obj");
});

Task("restore")
	.Description("还原项目依赖")
	.Does(() =>
{
	DotNetRestore(solutionFile);
});

Task("build")
	.Description("编译项目")
	.IsDependentOn("clean")
	.IsDependentOn("restore")
	.Does(() =>
{
	var settings = new DotNetBuildSettings
	{
		NoRestore = true
	};

	DotNetBuild(solutionFile, settings);
});

Task("deploy")
	.Description("部署插件")
	.Does(() =>
{
	DotNetTool(solutionFile, "deploy", $" -site:daemon -cloud:{cloud} -edition:{edition} -framework:{framework} -verbosity:quiet");
});

Task("default")
	.Description("默认")
	.IsDependentOn("build");

RunTarget(target);
