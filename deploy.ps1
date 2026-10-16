. (Join-Path $PSScriptRoot '.shared.ps1')

#region 执行流程
function Invoke-Deployment
{
	$local = $env:ZONGSOFT_HOSTING_LOCAL -eq '1'
	$root = (Get-Location).ProviderPath

	Write-Heading 'HOST DEPLOYMENT'
	[Console]::WriteLine("  $($style.Dim)Zongsoft Hosting  /  $root$($style.Reset)")
	$selectedHost = Read-HostProject $root
	$source = $selectedHost.Directory.Replace('\', '/')
	$settings = Read-DeploymentSettings

	if($local)
	{
		$compilation = 'Debug'
		$platform = 'windows'
		$architecture = 'x64'

		# Omit the framework override so Cake and .env retain their defaults.
		$framework = ''
	}
	else
	{
		Write-Heading '3. Build settings'

		$compilation = Read-Choice 'Configuration' @('Debug', 'Release') 'Debug' 'Default: Debug.'
		$platform = Read-Choice 'Platform' @('windows', 'linux', 'mac') 'windows' 'Default: windows.'
		$architecture = Read-Choice 'Architecture' @('x64', 'arm64') 'x64' 'Default: x64.'
		$framework = Read-Setting 'Framework' '' 'Enter: Cake default and .env.'
	}

	$output = if($selectedHost.Type -eq 'Web') { '.' } else { 'bin/${edition}/${framework}' }
	$overwrite = if($local) { 'alway' } else { 'newest' }

	Write-Heading 'Execution'
	Write-Detail 'Source' $source
	Write-Detail 'Scheme' $settings.Scheme
	Write-Detail 'Environment' $settings.Environment
	Write-Detail 'Network' $settings.Network
	Write-Detail 'Configuration' $compilation
	Write-Detail 'Target' "$platform-$architecture"

	if($framework)
	{
		Write-Detail 'Framework' $framework
	}

	Write-Detail 'Output' $output
	Write-Detail 'Overwrite' $overwrite
	[Console]::WriteLine()

	$script:stage = 'Build'

	if(-not (Test-Path -LiteralPath (Join-Path $source 'build.cake') -PathType Leaf))
	{
		throw 'The selected host has no build.cake file.'
	}

	Write-Heading '[1/2] Build host'
	$buildArguments = @('cake', "--edition=$compilation", "--platform=$platform", "--architecture=$architecture")

	if($framework)
	{
		$buildArguments += "--framework=$framework"
	}

	Invoke-HostTool 'dotnet' $buildArguments $source

	$script:stage = 'Deployment'
	Write-Heading '[2/2] Deploy assets'
	$toolArguments = @(
		'deploy',
		"--source:$source",
		"--output:$output",
		"--scheme:$($settings.Scheme)",
		"--environment:$($settings.Environment)",
		"--network:$($settings.Network)",
		"--edition:$compilation",
		"--platform:$platform",
		"--architecture:$architecture",
		'--verbosity:quiet',
		"--overwrite:$overwrite",
		'--prerelease:true'
	)

	if($framework)
	{
		$toolArguments += "--framework:$framework"
	}

	Invoke-HostTool 'dotnet' $toolArguments $root

	Write-Heading 'Result'
	[Console]::WriteLine("  $($style.Green)[OK] $stage completed successfully.$($style.Reset)")
	Wait-Finish
	$script:result = 0
}
#endregion

#region 脚本入口
Invoke-HostingOperation { Invoke-Deployment }
exit $script:result
#endregion
