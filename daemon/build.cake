var scheme = Argument("scheme", "default");
var target = Argument("target", "default");
var edition = Argument("edition", "Debug");
var platform = Argument("platform", "Windows");
var framework = Argument("framework", "net10.0");
var architecture = Argument("architecture", "x64");
var solutionFile  = "Zongsoft.Hosting.Daemon.slnx";

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
	var settings = new DotNetRestoreSettings
	{
		MSBuildSettings = new DotNetMSBuildSettings()
	};

	if(string.Equals(platform, "win", StringComparison.OrdinalIgnoreCase))
		platform = "Windows";

	if(!string.IsNullOrEmpty(platform))
		settings.MSBuildSettings.WithProperty("DefineConstants", platform.ToUpperInvariant());

	settings.MSBuildSettings.WithProperty("Platform", "Any CPU");
	DotNetRestore(solutionFile, settings);
});

Task("build")
	.Description("编译项目")
	.IsDependentOn("clean")
	.IsDependentOn("restore")
	.Does(() =>
{
	var settings = new DotNetBuildSettings
	{
		NoRestore = true,
		Configuration = edition,
		MSBuildSettings = new DotNetMSBuildSettings()
	};

	if(string.Equals(platform, "win", StringComparison.OrdinalIgnoreCase))
		platform = "Windows";

	if(!string.IsNullOrEmpty(platform))
		settings.MSBuildSettings.WithProperty("DefineConstants", platform.ToUpperInvariant());

	settings.MSBuildSettings.WithProperty("Platform", "Any CPU");
	DotNetBuild(solutionFile, settings);
});

Task("default")
	.Description("默认")
	.IsDependentOn("build");

RunTarget(target);
