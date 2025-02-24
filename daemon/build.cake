var scheme = Argument("scheme", "default");
var target = Argument("target", "default");
var edition = Argument("edition", "Debug");
var framework = Argument("framework", "net9.0");
var architecture = Argument("architecture", "x64");
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
	DotNetTool(solutionFile, "deploy", $" -host:daemon -site:daemon -scheme:{scheme} -edition:{edition} -framework:{framework} -architecture:{architecture} -verbosity:quiet");
});

Task("default")
	.Description("默认")
	.IsDependentOn("build");

RunTarget(target);
