param(
	[Parameter(ValueFromRemainingArguments = $true)]
	[string[]]$ToolArguments = @()
)

. (Join-Path $PSScriptRoot '.shared.ps1')

#region 输入设置
function Read-SavedDelivery([string]$Action, [string]$Root)
{
	$extension = if($Action -eq 'run') { '.tar.gz' } else { '.container' }
	$output = Join-Path $Root '.containerized'

	while($true)
	{
		Write-Heading '1. Saved delivery'
		$choices = @()

		if(Test-Path -LiteralPath $output -PathType Container)
		{
			$choices = @(Get-ChildItem -LiteralPath $output -File | Where-Object { $_.Name.EndsWith($extension, [StringComparison]::OrdinalIgnoreCase) } | Sort-Object Name | ForEach-Object {
				[pscustomobject]@{ Value = '.containerized/' + $_.Name; Label = $_.Name }
			})
		}

		$choices += [pscustomobject]@{ Value = 'manual'; Label = "Enter a $extension path manually" }
		$selected = Read-Menu "Existing $extension file" $choices $choices[0].Value 'Folder: .containerized. Esc: return to operation selection.' -AllowBack

		if($null -eq $selected)
		{
			return $null
		}

		if($selected.Value -ne 'manual')
		{
			return $selected.Value
		}

		while($true)
		{
			$path = Read-Setting 'Delivery file path' '' "Choose a $extension file. Esc: return to file selection." -AllowBack

			if($null -eq $path)
			{
				break
			}

			if($path.Length -eq 0)
			{
				continue
			}

			if($path.EndsWith($extension, [StringComparison]::OrdinalIgnoreCase))
			{
				return $path
			}

			Write-WarningMessage "Choose a $extension file."
		}
	}
}

function Read-ContainerSettings
{
	Write-Heading '1. Delivery settings'

	$name = Read-Setting 'Application name' 'zongsoft' 'Enter: zongsoft.'
	$tag = Read-Setting 'Build tag' '' 'Optional. Enter: no tag.'
	$version = Read-Setting 'Release version' '' 'Enter: automatic date version.'
	$distributions = @(
		[pscustomobject]@{ Value = 'ubuntu@22.04'; Label = 'Ubuntu 22.04 LTS' }
		[pscustomobject]@{ Value = 'debian@12'; Label = 'Debian 12' }
		[pscustomobject]@{ Value = 'debian@13'; Label = 'Debian 13' }
		[pscustomobject]@{ Value = 'rhel@9'; Label = 'RHEL 9' }
		[pscustomobject]@{ Value = 'rocky@9'; Label = 'Rocky Linux 9' }
		[pscustomobject]@{ Value = 'almalinux@9'; Label = 'AlmaLinux 9' }
	)

	$distribution = (Read-Menu 'Linux distribution' $distributions 'debian@13' 'Default: Debian 13.').Value
	$architecture = Read-Choice 'Architecture' @('x64', 'arm64') 'x64' 'Default: x64.'
	$engine = Read-Choice 'Build engine' @('auto', 'docker', 'podman') 'auto' 'Default: automatic.'
	$bootstrap = Read-Choice 'Bootstrap delivery' @('online', 'offline') 'offline' 'Engine dependencies. Default: offline.'
	$imaging = Read-Choice 'Image delivery' @('online', 'offline') 'offline' 'Container images. Default: offline.'
	$migrationChoices = @(
		[pscustomobject]@{ Value = 'none'; Label = 'No migrations (default)' }
		[pscustomobject]@{ Value = '.migration'; Label = '.migration' }
		[pscustomobject]@{ Value = 'manual'; Label = 'Enter a migration directory manually' }
	)

	while($true)
	{
		$migration = (Read-Menu 'Migration directory' $migrationChoices 'none' 'Default: no migrations.').Value

		if($migration -eq 'none')
		{
			$migration = ''
			break
		}

		if($migration -ne 'manual')
		{
			break
		}

		$migration = Read-Setting 'Migration path' '' 'Enter: no migrations. Esc: return to directory selection.' -AllowBack

		if($null -ne $migration)
		{
			break
		}
	}

	return [ordered]@{
		name = $name
		tag = $tag
		version = $version
		architecture = $architecture
		distribution = $distribution
		engine = $engine
		bootstrap = $bootstrap
		imaging = $imaging
		migration = $migration
	}
}

function Read-ContainerInputs([string]$Root)
{
	$projects = @(Get-HostProjects $Root)

	while($true)
	{
		Write-Heading '2. Basic services'
		[Console]::WriteLine("  $($style.Dim)Add one service per line, for example redis, mysql or rustfs.$($style.Reset)")
		[Console]::WriteLine("  $($style.Dim)Leave the next line empty to continue to host selection.$($style.Reset)")
		$services = [Collections.Generic.List[string]]::new()

		while($true)
		{
			$service = Read-Setting "Service $($services.Count + 1)" '' 'Service ID or service template path. Enter: continue to hosts.'

			if($service.Length -eq 0)
			{
				break
			}

			if($service.EndsWith('.container', [StringComparison]::OrdinalIgnoreCase))
			{
				Write-WarningMessage 'Use the make operation to choose an existing .container file.'

				continue
			}

			if($projects | Where-Object { $_.Value -ieq $service.Replace('\', '/') })
			{
				Write-WarningMessage 'Choose application hosts in the next menu; this field is for basic services.'

				continue
			}

			$services.Add($service)
		}

		Write-Heading '3. Application hosts'
		$hosts = @()

		if($projects.Count -gt 0)
		{
			$hosts = @(Read-Menu 'Host projects' @(Get-HostMenuItems $projects) 'daemon' 'Select zero or more hosts. Group headings are not selectable.' -Multiple)
		}
		else
		{
			[Console]::WriteLine("  $($style.Dim)No host projects found. Continuing with basic services only.$($style.Reset)")
		}

		if($services.Count -gt 0 -or $hosts.Count -gt 0)
		{
			Write-Detail 'Services' $(if($services.Count) { $services -join ', ' } else { '(none)' })
			Write-Detail 'Hosts' $(if($hosts.Count) { ($hosts | ForEach-Object { $_.Value }) -join ', ' } else { '(none)' })

			return @($services.ToArray()) + @($hosts | ForEach-Object { $_.Value })
		}

		Write-WarningMessage 'Choose at least one basic service or application host.'
	}
}
#endregion

#region 执行流程
function Complete-Containerization([string]$Action)
{
	if($Action -eq 'run')
	{
		return
	}

	Write-Heading 'Result'

	if($Action -eq 'plan')
	{
		[Console]::WriteLine("  $($style.Green)[OK] Plan completed successfully.$($style.Reset)")
		[Console]::WriteLine("  $($style.Dim)Editable .container created. Edit it, then run:$($style.Reset)")
		[Console]::WriteLine("  $($style.Cyan)containerize.cmd make FILE.container$($style.Reset)")
	}
	else
	{
		[Console]::WriteLine("  $($style.Green)[OK] Make completed successfully.$($style.Reset)")
		[Console]::WriteLine("  $($style.Dim)Container delivery artifacts and .container manifest created.$($style.Reset)")
	}

	Wait-Finish
}

function Invoke-Containerization
{
	$root = (Get-Location).ProviderPath
	$action = ''
	$refresh = $false

	Write-Heading 'CONTAINER DELIVERY'
	[Console]::WriteLine("  $($style.Dim)zongsoft  /  plan - make - run$($style.Reset)")

	if($ToolArguments.Count -eq 1 -and $ToolArguments[0] -ieq '--refresh')
	{
		$refresh = $true
	}
	elseif($ToolArguments.Count -gt 0)
	{
		$first = $ToolArguments[0]
		$arguments = @($ToolArguments)

		if($first -in @('plan', 'make', 'run'))
		{
			$action = $first.ToLowerInvariant()
		}
		elseif($first.EndsWith('.container', [StringComparison]::OrdinalIgnoreCase))
		{
			$action = 'make'
			$arguments = @('make') + $arguments
		}
		else
		{
			$script:result = 2
			throw 'Unknown operation. Usage: containerize.cmd [plan | make | run] [inputs and options]'
		}

		if($arguments.Count -gt 1)
		{
			Write-Heading 'Execution'
			Write-Detail 'Operation' $action
			$script:stage = 'Container ' + $action

			if($action -ne 'run')
			{
				$arguments += @('--source:.', '--output:.containerized')
			}

			Invoke-HostTool 'dotnet-containerize' $arguments $root
			Complete-Containerization $action

			return
		}
	}

	$operations = @(
		[pscustomobject]@{ Value = 'full'; Label = 'Create complete delivery' }
		[pscustomobject]@{ Value = 'plan'; Label = 'Plan editable .container only' }
		[pscustomobject]@{ Value = 'make'; Label = 'Make delivery from an existing .container' }
		[pscustomobject]@{ Value = 'run'; Label = 'Run an existing container delivery' }
	)

	while($true)
	{
		if(-not $action)
		{
			$action = (Read-Menu 'Operation' $operations 'full' 'Choose what to create or verify.').Value
		}

		$arguments = @()

		if($action -in @('make', 'run'))
		{
			$manifest = Read-SavedDelivery $action $root

			if($null -eq $manifest)
			{
				$action = ''

				continue
			}

			$arguments = @($action, $manifest)

			if($action -eq 'make')
			{
				$version = Read-Setting 'New release version' '' 'Enter: keep the manifest version.'

				if($version)
				{
					$arguments += "--version:$version"
				}
			}
		}
		else
		{
			$settings = Read-ContainerSettings
			$components = @(Read-ContainerInputs $root)

			if($action -eq 'plan')
			{
				$arguments += 'plan'
			}

			foreach($setting in $settings.GetEnumerator())
			{
				if($setting.Value)
				{
					$arguments += '--' + $setting.Key + ':' + $setting.Value
				}
			}

			$arguments += $components
		}

		if($action -ne 'run')
		{
			$arguments += @('--source:.', '--output:.containerized')
		}

		Write-Heading 'Execution'
		Write-Detail 'Operation' $action

		if($refresh -and $action -notin @('plan', 'run'))
		{
			[Console]::WriteLine("  $($style.Yellow)[REFRESH] Preparing new public runtime environments.$($style.Reset)")
			$arguments += '--refresh'
		}

		$script:stage = 'Container ' + $action
		Invoke-HostTool 'dotnet-containerize' $arguments $root
		Complete-Containerization $action

		return
	}
}
#endregion

#region 脚本入口
Invoke-HostingOperation { Invoke-Containerization } -Directory $PSScriptRoot
exit $script:result
#endregion
