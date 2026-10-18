. (Join-Path $PSScriptRoot '.shared.ps1')

#region 执行流程
function Invoke-Packaging
{
	$root = (Get-Location).ProviderPath

	Write-Heading 'HOST PACKAGING'
	[Console]::WriteLine("  $($style.Dim)Zongsoft Hosting  /  $root$($style.Reset)")
	$selectedHost = Read-HostProject $root
	$source = $selectedHost.Directory.Replace('\', '/')
	$settings = Read-DeploymentSettings
	$framework = Get-HostingFramework

	Write-Heading '3. Build settings'

	$compilation = Read-Choice 'Compilation' @('Release', 'Debug') 'Release' 'Match the existing host output.'
	$architecture = Read-Choice 'Architecture' @('x64', 'arm64') 'x64' 'Default: x64.'

	Write-Heading '4. Package settings'

	$format = Read-Choice 'Format' @('tar', 'deb', 'rpm') 'tar' 'Default: tar. Target platform: Linux.'
	$edition = Read-Setting 'Edition' '' 'Enter: default edition.'
	$version = Read-Setting 'Version' '' 'Enter: source version.'
	$migration = (Read-Setting 'Migration' '' 'Existing migration name or path. Enter: none.').Replace('\', '/')
	$output = (Read-Setting 'Output' '.packages' 'Enter: .packages. Relative paths use the selected source.').Replace('\', '/')

	Write-Heading 'Execution'
	Write-Detail 'Source' $source
	Write-Detail 'Scheme' $settings.Scheme
	Write-Detail 'Environment' $settings.Environment
	Write-Detail 'Network' $settings.Network
	Write-Detail 'Configuration' $compilation
	Write-Detail 'Target' "linux-$architecture"

	Write-Detail 'Framework' $framework

	Write-Detail 'Output' $output
	Write-Detail 'Overwrite' 'true'
	[Console]::WriteLine()

	$script:stage = 'Packaging'
	$toolArguments = @(
		$format,
		"--source:$source",
		'--name:${application:name}',
		'--title:${application:title}',
		'--daemon:${application:daemon}',
		"--edition:$edition",
		"--version:$version",
		"--compilation:$compilation",
		'--platform:linux',
		"--architecture:$architecture",
		"--framework:$framework",
		'--overwrite=true',
		"--scheme:$($settings.Scheme)",
		"--network:$($settings.Network)",
		"--migration:$migration",
		"--Environment:$($settings.Environment)",
		"--DOTNET_ENVIRONMENT:$($settings.Environment)",
		"--output:$output"
	)

	if($selectedHost.Type -eq 'Web')
	{
		$toolArguments += @(
			"--ASPNETCORE_ENVIRONMENT:$($settings.Environment)",
			'--web:nginx',
			'--daemon-environments:Environment,DOTNET_ENVIRONMENT,ASPNETCORE_ENVIRONMENT',
			'--exclude:**/logs/;bin/${compilation}/${framework}/*.staticwebassets.*;bin/${compilation}/${framework}/plugins/**',
			'../../mime',
			'appsettings.json',
			'web*.config',
			'web.option',
			'${application:name}.option',
			'wwwroot',
			'plugins',
			'bin/${compilation}/${framework}:~'
		)
	}
	else
	{
		$toolArguments += @('--daemon-environments:Environment,DOTNET_ENVIRONMENT', '--exclude:**/logs/;', 'bin/${compilation}/${framework}:~')
	}

	Invoke-HostTool 'dotnet-pack' $toolArguments $root

	Write-Heading 'Result'
	[Console]::WriteLine("  $($style.Green)[OK] $stage completed successfully.$($style.Reset)")
	Wait-Finish
	$script:result = 0
}
#endregion

#region 脚本入口
Invoke-HostingOperation { Invoke-Packaging }
exit $script:result
#endregion
