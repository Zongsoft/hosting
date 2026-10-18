. (Join-Path $PSScriptRoot '.shared.ps1')

#region 执行流程
function Invoke-Migration
{
	$root = (Get-Location).ProviderPath
	$migrationRoot = '.deploy/${scheme}/migration/${version}'

	Write-Heading 'MIGRATION ARTIFACTS'
	[Console]::WriteLine("  $($style.Dim)zongsoft  /  dotnet-migrate$($style.Reset)")
	Write-Heading '1. Migration settings'

	$name = Read-Setting 'Migration name' 'zongsoft' 'Enter: zongsoft.'
	$edition = Read-Setting 'Edition' '' 'Optional. Enter: no edition.'

	do
	{
		$version = Read-Setting 'Version' '' 'Required. Version number, version file or directory.'

		if(-not $version)
		{
			Write-WarningMessage 'Enter a version number, version file or directory.'
		}
	} while(-not $version)

	$platform = Read-Choice 'Target platform' @('linux', 'windows') 'linux' 'Default: linux.'
	$architecture = Read-Choice 'Architecture' @('x64', 'arm64') 'x64' 'Default: x64.'
	$scheme = Read-DeploymentScheme 'Deployment scheme'

	Write-Heading '2. Migration inputs'
	[Console]::WriteLine("  $($style.Dim)Add one file or pattern per line; leave the next line empty to finish.$($style.Reset)")
	[Console]::WriteLine("  $($style.Dim)Bare filenames use $migrationRoot/.$($style.Reset)")
	[Console]::WriteLine("  $($style.Dim)Paths with / or \ remain relative to hosting, or absolute as entered.$($style.Reset)")
	$inputs = [Collections.Generic.List[string]]::new()

	while($true)
	{
		$hint = if($inputs.Count) { 'Enter: finish input selection.' } else { 'Enter: all *.migration files in the scheme/version directory.' }
		$inputPath = Read-Setting "Migration input $($inputs.Count + 1)" '' $hint

		if(-not $inputPath)
		{
			if($inputs.Count -eq 0)
			{
				$inputs.Add($migrationRoot + '/*.migration')
			}

			break
		}

		if($inputPath -eq '*')
		{
			Write-WarningMessage 'Use *.migration, or leave the first path empty to select all migration files.'

			continue
		}

		if($inputPath.EndsWith('/*', [StringComparison]::Ordinal))
		{
			$inputPath = $inputPath.Substring(0, $inputPath.Length - 1) + '*.migration'
		}

		if(-not $inputPath.Contains('/') -and -not $inputPath.Contains('\'))
		{
			$inputPath = $migrationRoot + '/' + $inputPath
		}

		$inputs.Add($inputPath)
	}

	Write-Heading 'Execution'
	Write-Detail 'Name' $name

	if($edition)
	{
		Write-Detail 'Edition' $edition
	}

	Write-Detail 'Version' $version
	Write-Detail 'Runtime' "$platform-$architecture"
	Write-Detail 'Scheme' $scheme
	Write-Detail 'Output' '.migration'
	Write-Detail 'Inputs' "$($inputs.Count) pattern(s)"

	$arguments = @(
		"--name:$name",
		"--edition:$edition",
		"--version:$version",
		"--platform:$platform",
		"--architecture:$architecture",
		"--scheme:$scheme",
		'--output:.migration'
	) + $inputs.ToArray()

	$script:stage = 'Migration'
	Invoke-HostTool 'dotnet-migrate' $arguments $root

	Write-Heading 'Result'
	[Console]::WriteLine("  $($style.Green)[OK] Migration artifacts created successfully.$($style.Reset)")
}
#endregion

#region 脚本入口
Invoke-HostingOperation { Invoke-Migration } -Directory $PSScriptRoot
exit $script:result
#endregion
