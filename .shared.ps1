param(
	[Parameter(Mandatory = $true)]
	[ValidateSet('Deploy', 'Pack', 'Containerize', 'Migrate')]
	[string]$Operation,

	[Parameter(ValueFromRemainingArguments = $true)]
	[string[]]$ToolArguments = @()
)

# Shared interaction and execution for the hosting CMD entry points.
#region Shared interaction and host discovery
$ErrorActionPreference = 'Stop'
$interactive = -not [Console]::IsInputRedirected -and -not [Console]::IsOutputRedirected
$useColor = -not [Console]::IsOutputRedirected -and -not (Test-Path Env:NO_COLOR)
$escape = [char]27
$style = @{
	Heading = ''
	Cyan = ''
	Green = ''
	Yellow = ''
	Red = ''
	Magenta = ''
	Dim = ''
	Reset = ''
}

if($useColor) {
	$style.Heading = "$escape[1;96m"
	$style.Cyan = "$escape[96m"
	$style.Green = "$escape[92m"
	$style.Yellow = "$escape[33m"
	$style.Red = "$escape[31m"
	$style.Magenta = "$escape[95m"
	$style.Dim = "$escape[90m"
	$style.Reset = "$escape[0m"
}

function Write-Heading([string]$Text) {
	[Console]::WriteLine()
	[Console]::WriteLine("  $($style.Heading)$Text$($style.Reset)")
	[Console]::WriteLine("  $($style.Dim)------------------------------------------------------------$($style.Reset)")
}

function Write-Detail([string]$Label, [string]$Value) {
	[Console]::WriteLine(('  {0}{1,-16}{2}{3}{4}' -f $style.Dim, ($Label + ':'), $style.Cyan, $Value, $style.Reset))
}

function Read-Setting([string]$Label, [string]$Default = '', [string]$Hint = '', [switch]$AllowBack) {
	if($interactive) {
		# Reserve the hint line before returning the cursor to the input field.
		[Console]::Write("  $($style.Cyan)${Label}: $($style.Reset)")
		$left = [Console]::CursorLeft
		[Console]::WriteLine()
		[Console]::WriteLine("  $($style.Dim)$Hint$($style.Reset)")
		$top = [Math]::Max(0, [Console]::CursorTop - 2)
		[Console]::SetCursorPosition($left, $top)

		try {
			if($AllowBack) {
				$buffer = [Text.StringBuilder]::new()

				while($true) {
					$key = [Console]::ReadKey($true)

					if($key.Key -eq 'Escape') {
						[Console]::WriteLine()
						return $null
					}

					if($key.Key -eq 'Enter') {
						[Console]::WriteLine()
						break
					}

					if($key.Key -eq 'Backspace') {
						if($buffer.Length -gt 0) {
							[void]$buffer.Remove($buffer.Length - 1, 1)
							[Console]::Write("`b `b")
						}

						continue
					}

					if(-not [char]::IsControl($key.KeyChar)) {
						[void]$buffer.Append($key.KeyChar)
						[Console]::Write($key.KeyChar)
					}
				}

				$answer = $buffer.ToString()
			} else {
				$answer = [Console]::ReadLine()
			}
		}
		finally {
			[Console]::SetCursorPosition(0, [Math]::Max([Console]::CursorTop, $top + 2))
		}
	} else {
		[Console]::WriteLine("  ${Label}:")
		if($Hint) { [Console]::WriteLine("  $Hint") }
		$answer = [Console]::ReadLine()
	}

	[Console]::WriteLine()

	if($null -eq $answer) { throw [OperationCanceledException]::new() }
	$answer = $answer.Trim()

	if($answer.Length -ge 2 -and $answer.StartsWith('"') -and $answer.EndsWith('"')) {
		$answer = $answer.Substring(1, $answer.Length - 2).Trim()
	}

	if($AllowBack -and $answer -ieq 'esc') { return $null }
	if($answer.Length -eq 0) { return $Default }
	return $answer
}

function Format-MenuRow($Row, [int]$Index, [bool[]]$Checked, [switch]$Multiple) {
	$indent = '  ' * [int]$Row.Item.Depth

	if($Row.Number -eq 0) {
		return '      {0}{1}' -f $indent, $Row.Item.Label
	}

	$marker = if($Row.Number -eq $Index + 1) { '> ' } else { '  ' }
	$check = if($Multiple) { if($Checked[$Row.Number - 1]) { '[x] ' } else { '[ ] ' } } else { '' }
	return '    {0}{1}{2}{3}. {4}' -f $marker, $indent, $check, $Row.Number, $Row.Item.Label
}

function Read-Menu([string]$Label, [object[]]$Items, [string]$Default, [string]$Hint = '', [switch]$Multiple, [switch]$AllowBack) {
	$choices = [Collections.Generic.List[object]]::new()
	$positions = [Collections.Generic.List[int]]::new()
	$display = [Collections.Generic.List[object]]::new()

	foreach($item in $Items) {
		$number = 0

		if(-not $item.Group) {
			$positions.Add($display.Count)
			$choices.Add($item)
			$number = $choices.Count
		}

		$display.Add([pscustomobject]@{ Item = $item; Number = $number })
	}

	if($choices.Count -eq 0) { throw 'There are no choices available.' }

	[Console]::WriteLine("  $($style.Cyan)$Label$($style.Reset)")
	if($Hint) { [Console]::WriteLine("  $($style.Dim)$Hint$($style.Reset)") }

	$index = 0
	$checked = [bool[]]::new($choices.Count)

	for($row = 0; $row -lt $choices.Count; $row++) {
		if($choices[$row].Value -eq $Default) {
			$index = $row
			break
		}
	}

	if(-not $interactive) {
		foreach($row in $display) {
			[Console]::WriteLine((Format-MenuRow $row -1 $checked -Multiple:$Multiple))
		}

		while($true) {
			$defaultAnswer = if($Multiple) { '' } else { [string]($index + 1) }
			$inputHint = if($Multiple) { 'Numbers separated by commas, or a listed path. Enter: no hosts. Esc: cancel.' } else { "Number or listed value. Enter: $($index + 1). Esc: back/cancel." }
			$answer = Read-Setting 'Option' $defaultAnswer $inputHint

			if($answer -ieq 'esc') {
				if($AllowBack) { return $null }
				throw [OperationCanceledException]::new()
			}

			if($Multiple -and $answer.Length -eq 0) { return }

			# A complete value is checked first so a literal path may contain commas.
			$answers = @($answer)
			if($Multiple -and -not ($choices | Where-Object { $_.Value -ieq $answer })) {
				$answers = @($answer.Split(',') | ForEach-Object { $_.Trim() })
			}

			$selected = [Collections.Generic.HashSet[int]]::new()
			$valid = $true

			foreach($value in $answers) {
				$found = $false

				for($row = 0; $row -lt $choices.Count; $row++) {
					if($value -eq [string]($row + 1) -or $value -ieq $choices[$row].Value) {
						[void]$selected.Add($row)
						$found = $true
						break
					}
				}

				if(-not $found) { $valid = $false }
			}

			if($valid) {
				for($row = 0; $row -lt $choices.Count; $row++) {
					if($selected.Contains($row)) { $choices[$row] }
				}

				return
			}

			Write-WarningMessage 'Invalid selection. Choose one of the numbered options; group headings cannot be selected.'
		}
	}

	$keys = if($Multiple) { 'Up/Down: move   Space: toggle   Enter: confirm   Esc: cancel' } else { 'Up/Down: move   Enter: confirm   Esc: back/cancel' }
	[Console]::WriteLine("    $($style.Dim)$keys$($style.Reset)")

	$rows = [Math]::Min($display.Count, [Math]::Max(1, [Math]::Min(10, [Console]::WindowHeight - 6)))
	for($row = 0; $row -lt $rows; $row++) { [Console]::WriteLine() }

	$top = [Console]::CursorTop - $rows
	$foreground = [Console]::ForegroundColor
	$background = [Console]::BackgroundColor
	$cursor = [Console]::CursorVisible
	$first = 0

	try {
		[Console]::CursorVisible = $false

		while($true) {
			$position = $positions[$index]
			if($position -lt $first) { $first = $position }
			if($position -ge $first + $rows) { $first = $position - $rows + 1 }

			[Console]::SetCursorPosition(0, $top)
			$width = [Math]::Max(1, [Console]::BufferWidth - 1)

			for($row = 0; $row -lt $rows; $row++) {
				$current = $first + $row

				if($useColor) {
					[Console]::ForegroundColor = if($display[$current].Number -eq 0) { 'DarkGray' } else { $foreground }
					[Console]::BackgroundColor = $background

					if($current -eq $position) {
						[Console]::ForegroundColor = 'White'
						[Console]::BackgroundColor = 'DarkCyan'
					}
				}

				$line = Format-MenuRow $display[$current] $index $checked -Multiple:$Multiple
				if($line.Length -gt $width) { $line = $line.Substring(0, $width) }
				[Console]::WriteLine($line.PadRight($width))
			}

			if($useColor) {
				[Console]::ForegroundColor = $foreground
				[Console]::BackgroundColor = $background
			}

			switch([Console]::ReadKey($true).Key) {
				'UpArrow' { $index = ($index + $choices.Count - 1) % $choices.Count }
				'DownArrow' { $index = ($index + 1) % $choices.Count }
				'Home' { $index = 0 }
				'End' { $index = $choices.Count - 1 }
				'Spacebar' { if($Multiple) { $checked[$index] = -not $checked[$index] } }
				'Enter' {
					if($Multiple) {
						for($row = 0; $row -lt $choices.Count; $row++) {
							if($checked[$row]) { $choices[$row] }
						}

						return
					}

					return $choices[$index]
				}
				'Escape' {
					if($AllowBack) { return $null }
					throw [OperationCanceledException]::new()
				}
			}
		}
	}
	finally {
		if($useColor) {
			[Console]::ForegroundColor = $foreground
			[Console]::BackgroundColor = $background
		}

		[Console]::CursorVisible = $cursor
		[Console]::SetCursorPosition(0, $top + $rows)
		[Console]::WriteLine()
	}
}

function Read-Choice([string]$Label, [string[]]$Values, [string]$Default, [string]$Hint = '') {
	$choices = @($Values | ForEach-Object { [pscustomobject]@{ Value = $_; Label = $_ } })
	return (Read-Menu $Label $choices $Default $Hint).Value
}

function Get-HostProject([string]$Directory, [string]$RelativePath) {
	if(-not (Test-Path -LiteralPath (Join-Path $Directory '.deploy') -PathType Leaf)) { return }

	foreach($type in @('Daemon', 'Terminal', 'Web')) {
		if(Test-Path -LiteralPath (Join-Path $Directory "Zongsoft.Hosting.$type.csproj") -PathType Leaf) {
			return [pscustomobject]@{
				Value = $RelativePath.Replace('\', '/')
				Label = if($RelativePath -eq '.') { (Get-Item -LiteralPath $Directory).Name } else { ($RelativePath.Replace('\', '/') -split '/')[-1] }
				Directory = $Directory
				Type = $type
			}
		}
	}
}

function Get-HostProjects([string]$Root) {
	$pending = [Collections.Generic.Queue[object]]::new()
	$pending.Enqueue([pscustomobject]@{ Directory = $Root; RelativePath = '.' })

	while($pending.Count -gt 0) {
		$current = $pending.Dequeue()
		$project = Get-HostProject $current.Directory $current.RelativePath

		if($null -ne $project) {
			$project
			continue
		}

		foreach($directory in Get-ChildItem -LiteralPath $current.Directory -Directory | Sort-Object Name) {
			if($directory.Name.StartsWith('.') -or $directory.Name -in @('bin', 'obj', 'packages', 'node_modules') -or
				($directory.Attributes -band [IO.FileAttributes]::ReparsePoint)) { continue }

			$relative = if($current.RelativePath -eq '.') { $directory.Name } else { $current.RelativePath + '/' + $directory.Name }
			$pending.Enqueue([pscustomobject]@{ Directory = $directory.FullName; RelativePath = $relative })
		}
	}
}

function Get-HostMenuItems([object[]]$Projects, [int]$Depth = 0) {
	# Sort each directory level independently; group headings never become choices.
	$groups = $Projects | Group-Object { $_.Value.Split('/')[$Depth] } | Sort-Object Name

	foreach($group in $groups) {
		$project = $group.Group[0]

		if($project.Value.Split('/').Length -gt $Depth + 1) {
			[pscustomobject]@{ Label = $group.Name; Depth = $Depth; Group = $true }
			Get-HostMenuItems $group.Group ($Depth + 1)
		} else {
			[pscustomobject]@{
				Value = $project.Value
				Label = $project.Label
				Directory = $project.Directory
				Type = $project.Type
				Depth = $Depth
				Group = $false
			}
		}
	}
}

function Write-WarningMessage([string]$Text) {
	[Console]::WriteLine("  $($style.Yellow)[WARN] $Text$($style.Reset)")
}

function Invoke-HostTool([string]$Command, [string[]]$Arguments, [string]$Directory) {
	Push-Location -LiteralPath $Directory

	try {
		# Invoke the native tool with separate arguments; never evaluate a command string.
		& $Command @Arguments
		$script:result = $LASTEXITCODE
	}
	finally { Pop-Location }

	if($script:result -ne 0) { throw "$Command failed." }
}

function Wait-Finish {
	if(-not $interactive) { return }

	[Console]::WriteLine()
	[Console]::WriteLine("  $($style.Dim)Press any key to finish.$($style.Reset)")
	[void][Console]::ReadKey($true)
}
#endregion

#region Deployment and packaging
function Invoke-HostOperation {
	$localDebug = $Operation -eq 'Deploy' -and $env:ZONGSOFT_HOSTING_LOCAL_DEBUG -eq '1'
	$root = (Get-Location).ProviderPath
	$title = if($Operation -eq 'Deploy') { 'HOST DEPLOYMENT' } else { 'HOST PACKAGING' }

	Write-Heading $title
	[Console]::WriteLine("  $($style.Dim)Zongsoft Hosting  /  $root$($style.Reset)")
	Write-Heading '1. Host project'

	if($env:ZONGSOFT_HOSTING_SOURCE) {
		$requested = $env:ZONGSOFT_HOSTING_SOURCE
		$directory = if([IO.Path]::IsPathRooted($requested)) { $requested } else { Join-Path $root $requested }
		$directory = [IO.Path]::GetFullPath($directory)
		$selectedHost = Get-HostProject $directory $requested

		if($null -eq $selectedHost) { throw "Source must contain .deploy and a Zongsoft host project: $requested" }
	} else {
		$projects = @(Get-HostProjects $root)

		if($projects.Count -eq 0) { throw "No host projects found in $root. Expected .deploy and Zongsoft.Hosting.Daemon/Terminal/Web.csproj." }

		$selectedHost = Read-Menu 'Source' @(Get-HostMenuItems $projects) 'daemon' 'Choose a host project from the current directory.'
	}

	$source = $selectedHost.Directory.Replace('\', '/')
	Write-Detail 'Source' $selectedHost.Value
	Write-Detail 'Host' $selectedHost.Type

	Write-Heading '2. Deployment settings'

	$scheme = Read-Setting 'Scheme' 'default' 'Enter: default.'
	$defaultEnvironment = if([string]::IsNullOrWhiteSpace($env:Environment)) { 'development' } else { $env:Environment }
	$environment = Read-Setting 'Environment' $defaultEnvironment "Enter: $defaultEnvironment. Examples: development, test, production."
	$network = Read-Choice 'Network' @('internal', 'external') 'internal' 'Choose the network used by this deployment.'
	$env:Environment = $environment

	if($localDebug) {
		$debug = 'on'
		$compilation = 'Debug'
		$platform = 'windows'
		$architecture = 'x64'

		# Omit the framework override so Cake and .env retain their defaults.
		$framework = ''
	} else {
		Write-Heading '3. Build settings'

		if($Operation -eq 'Deploy') {
			$debug = Read-Choice 'Debug mode' @('on', 'off') 'on' 'On: Debug / Windows. Off: Release / Linux.'
			$compilation = if($debug -eq 'on') { 'Debug' } else { 'Release' }
			$defaultPlatform = if($debug -eq 'on') { 'windows' } else { 'linux' }
			$platform = Read-Choice 'Platform' @('windows', 'linux', 'mac') $defaultPlatform "Default: $defaultPlatform."
		} else {
			$compilation = Read-Choice 'Compilation' @('Release', 'Debug') 'Release' 'Match the existing host output.'
			$platform = 'linux'
		}

		$architecture = Read-Choice 'Architecture' @('x64', 'arm64') 'x64' 'Default: x64.'
		$frameworkHint = if($Operation -eq 'Deploy') { 'Enter: Cake default and .env.' } else { 'Enter: .env; match the existing host output.' }
		$framework = Read-Setting 'Framework' '' $frameworkHint
	}

	if($Operation -eq 'Pack') {
		Write-Heading '4. Package settings'

		$format = Read-Choice 'Format' @('tar', 'deb', 'rpm') 'tar' 'Default: tar. Target platform: Linux.'
		$edition = Read-Setting 'Edition' '' 'Enter: default edition.'
		$version = Read-Setting 'Version' '' 'Enter: source version.'
		$migration = (Read-Setting 'Migration' '' 'Existing migration name or path. Enter: none.').Replace('\', '/')
		$output = (Read-Setting 'Output' '.packages' 'Enter: .packages. Relative paths use the selected source.').Replace('\', '/')
	} else {
		$output = if($selectedHost.Type -eq 'Web') { '.' } else { 'bin/${edition}/${framework}' }
		$overwrite = if($localDebug) { 'alway' } else { 'newest' }
	}

	Write-Heading 'Execution'
	Write-Detail 'Source' $source
	Write-Detail 'Scheme' $scheme
	Write-Detail 'Environment' $environment
	Write-Detail 'Network' $network
	Write-Detail 'Configuration' $compilation
	Write-Detail 'Target' "$platform-$architecture"
	if($framework) { Write-Detail 'Framework' $framework }
	Write-Detail 'Output' $output
	if($Operation -eq 'Deploy') { Write-Detail 'Overwrite' $overwrite }
	[Console]::WriteLine()

	if($Operation -eq 'Deploy') {
		$script:stage = 'Build'

		if(-not (Test-Path -LiteralPath (Join-Path $source 'build.cake') -PathType Leaf)) { throw 'The selected host has no build.cake file.' }

		Write-Heading '[1/2] Build host'
		$buildArguments = @('cake', "--edition=$compilation", "--platform=$platform", "--architecture=$architecture")
		if($framework) { $buildArguments += "--framework=$framework" }

		Invoke-HostTool 'dotnet' $buildArguments $source

		$script:stage = 'Deployment'
		Write-Heading '[2/2] Deploy assets'
		$toolArguments = @('deploy', "--source:$source", "--output:$output", "--scheme:$scheme", "--environment:$environment",
			"--network:$network", "--debug:$debug", "--edition:$compilation", "--platform:$platform", "--architecture:$architecture",
			'--verbosity:quiet', "--overwrite:$overwrite", '--prerelease:true')
		if($framework) { $toolArguments += "--framework:$framework" }

		Invoke-HostTool 'dotnet' $toolArguments $root
	} else {
		$script:stage = 'Packaging'
		$toolArguments = @($format, "--source:$source", '--name:${application:name}', '--title:${application:title}', '--daemon:${application:daemon}',
			"--edition:$edition", "--version:$version", "--compilation:$compilation", '--platform:linux', "--architecture:$architecture",
			"--scheme:$scheme", "--network:$network", "--migration:$migration", "--Environment:$environment", "--DOTNET_ENVIRONMENT:$environment", "--output:$output")
		if($framework) { $toolArguments += "--framework:$framework" }

		if($selectedHost.Type -eq 'Web') {
			$toolArguments += @("--ASPNETCORE_ENVIRONMENT:$environment", '--web:nginx', '--daemon-environments:Environment,DOTNET_ENVIRONMENT,ASPNETCORE_ENVIRONMENT',
				'--exclude:**/logs/;bin/${compilation}/${framework}/*.staticwebassets.*', '../../mime', 'appsettings.json', 'web*.config', 'web*.option', 'wwwroot', 'plugins', 'bin/${compilation}/${framework}:~')
		} else {
			$toolArguments += @('--daemon-environments:Environment,DOTNET_ENVIRONMENT', '--exclude:**/logs/;', 'bin/${compilation}/${framework}:~')
		}

		Invoke-HostTool 'dotnet-pack' $toolArguments $root
	}

	Write-Heading 'Result'
	[Console]::WriteLine("  $($style.Green)[OK] $stage completed successfully.$($style.Reset)")
	Wait-Finish
	$script:result = 0
}
#endregion

#region Container delivery
function Read-SavedDelivery([string]$Action, [string]$Root) {
	$extension = if($Action -eq 'run') { '.tar.gz' } else { '.container' }
	$output = Join-Path $Root '.containerized'

	while($true) {
		Write-Heading '1. Saved delivery'
		$choices = @()

		if(Test-Path -LiteralPath $output -PathType Container) {
			$choices = @(Get-ChildItem -LiteralPath $output -File | Where-Object { $_.Name.EndsWith($extension, [StringComparison]::OrdinalIgnoreCase) } | Sort-Object Name | ForEach-Object {
				[pscustomobject]@{ Value = '.containerized/' + $_.Name; Label = $_.Name }
			})
		}

		$choices += [pscustomobject]@{ Value = 'manual'; Label = "Enter a $extension path manually" }
		$selected = Read-Menu "Existing $extension file" $choices $choices[0].Value 'Folder: .containerized. Esc: return to operation selection.' -AllowBack
		if($null -eq $selected) { return $null }
		if($selected.Value -ne 'manual') { return $selected.Value }

		while($true) {
			$path = Read-Setting 'Delivery file path' '' "Choose a $extension file. Esc: return to file selection." -AllowBack
			if($null -eq $path) { break }
			if($path.Length -eq 0) { continue }

			if($path.EndsWith($extension, [StringComparison]::OrdinalIgnoreCase)) {
				return $path
			}

			Write-WarningMessage "Choose a $extension file."
		}
	}
}

function Read-ContainerSettings {
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

	while($true) {
		$migration = (Read-Menu 'Migration directory' $migrationChoices 'none' 'Default: no migrations.').Value

		if($migration -eq 'none') {
			$migration = ''
			break
		}

		if($migration -ne 'manual') { break }

		$migration = Read-Setting 'Migration path' '' 'Enter: no migrations. Esc: return to directory selection.' -AllowBack
		if($null -ne $migration) { break }
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

function Read-ContainerInputs([string]$Root) {
	$projects = @(Get-HostProjects $Root)

	while($true) {
		Write-Heading '2. Basic services'
		[Console]::WriteLine("  $($style.Dim)Add one service per line, for example redis, mysql or rustfs.$($style.Reset)")
		[Console]::WriteLine("  $($style.Dim)Leave the next line empty to continue to host selection.$($style.Reset)")
		$services = [Collections.Generic.List[string]]::new()

		while($true) {
			$service = Read-Setting "Service $($services.Count + 1)" '' 'Service ID or service template path. Enter: continue to hosts.'
			if($service.Length -eq 0) { break }

			if($service.EndsWith('.container', [StringComparison]::OrdinalIgnoreCase)) {
				Write-WarningMessage 'Use the make operation to choose an existing .container file.'
				continue
			}

			if($projects | Where-Object { $_.Value -ieq $service.Replace('\', '/') }) {
				Write-WarningMessage 'Choose application hosts in the next menu; this field is for basic services.'
				continue
			}

			$services.Add($service)
		}

		Write-Heading '3. Application hosts'
		$hosts = @()

		if($projects.Count -gt 0) {
			$hosts = @(Read-Menu 'Host projects' @(Get-HostMenuItems $projects) 'daemon' 'Select zero or more hosts. Group headings are not selectable.' -Multiple)
		} else {
			[Console]::WriteLine("  $($style.Dim)No host projects found. Continuing with basic services only.$($style.Reset)")
		}

		if($services.Count -gt 0 -or $hosts.Count -gt 0) {
			Write-Detail 'Services' $(if($services.Count) { $services -join ', ' } else { '(none)' })
			Write-Detail 'Hosts' $(if($hosts.Count) { ($hosts | ForEach-Object { $_.Value }) -join ', ' } else { '(none)' })

			return @($services.ToArray()) + @($hosts | ForEach-Object { $_.Value })
		}

		Write-WarningMessage 'Choose at least one basic service or application host.'
	}
}

function Complete-Containerization([string]$Action) {
	if($Action -eq 'run') { return }

	Write-Heading 'Result'

	if($Action -eq 'plan') {
		[Console]::WriteLine("  $($style.Green)[OK] Plan completed successfully.$($style.Reset)")
		[Console]::WriteLine("  $($style.Dim)Editable .container created. Edit it, then run:$($style.Reset)")
		[Console]::WriteLine("  $($style.Cyan)containerize.cmd make FILE.container$($style.Reset)")
	} else {
		[Console]::WriteLine("  $($style.Green)[OK] Make completed successfully.$($style.Reset)")
		[Console]::WriteLine("  $($style.Dim)Container delivery artifacts and .container manifest created.$($style.Reset)")
	}

	Wait-Finish
}

function Invoke-Containerization {
	$root = (Get-Location).ProviderPath
	$action = ''
	$refresh = $false

	Write-Heading 'CONTAINER DELIVERY'
	[Console]::WriteLine("  $($style.Dim)zongsoft  /  plan - make - run$($style.Reset)")

	if($ToolArguments.Count -eq 1 -and $ToolArguments[0] -ieq '--refresh') {
		$refresh = $true
	} elseif($ToolArguments.Count -gt 0) {
		$first = $ToolArguments[0]
		$arguments = @($ToolArguments)

		if($first -in @('plan', 'make', 'run')) {
			$action = $first.ToLowerInvariant()
		} elseif($first.EndsWith('.container', [StringComparison]::OrdinalIgnoreCase)) {
			$action = 'make'
			$arguments = @('make') + $arguments
		} else {
			$script:result = 2
			throw 'Unknown operation. Usage: containerize.cmd [plan | make | run] [inputs and options]'
		}

		if($arguments.Count -gt 1) {
			Write-Heading 'Execution'
			Write-Detail 'Operation' $action
			$script:stage = 'Container ' + $action

			if($action -ne 'run') { $arguments += @('--source:.', '--output:.containerized') }
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

	while($true) {
		if(-not $action) {
			$action = (Read-Menu 'Operation' $operations 'full' 'Choose what to create or verify.').Value
		}

		$arguments = @()

		if($action -in @('make', 'run')) {
			$manifest = Read-SavedDelivery $action $root

			if($null -eq $manifest) {
				$action = ''
				continue
			}

			$arguments = @($action, $manifest)

			if($action -eq 'make') {
				$version = Read-Setting 'New release version' '' 'Enter: keep the manifest version.'
				if($version) { $arguments += "--version:$version" }
			}
		} else {
			$settings = Read-ContainerSettings
			$components = @(Read-ContainerInputs $root)

			if($action -eq 'plan') { $arguments += 'plan' }

			foreach($setting in $settings.GetEnumerator()) {
				if($setting.Value) { $arguments += '--' + $setting.Key + ':' + $setting.Value }
			}

			$arguments += $components
		}

		if($action -ne 'run') { $arguments += @('--source:.', '--output:.containerized') }

		Write-Heading 'Execution'
		Write-Detail 'Operation' $action

		if($refresh -and $action -notin @('plan', 'run')) {
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

#region Migration artifacts
function Invoke-Migration {
	$root = (Get-Location).ProviderPath
	$migrationRoot = '.deploy/${scheme}/migration/${version}'

	Write-Heading 'MIGRATION ARTIFACTS'
	[Console]::WriteLine("  $($style.Dim)zongsoft  /  dotnet-migrate$($style.Reset)")
	Write-Heading '1. Migration settings'

	$name = Read-Setting 'Migration name' 'zongsoft' 'Enter: zongsoft.'
	$edition = Read-Setting 'Edition' '' 'Optional. Enter: no edition.'

	do {
		$version = Read-Setting 'Version' '' 'Required. Version number, version file or directory.'
		if(-not $version) { Write-WarningMessage 'Enter a version number, version file or directory.' }
	} while(-not $version)

	$platform = Read-Choice 'Target platform' @('linux', 'windows') 'linux' 'Default: linux.'
	$architecture = Read-Choice 'Architecture' @('x64', 'arm64') 'x64' 'Default: x64.'
	$scheme = Read-Setting 'Deployment scheme' 'default' 'Enter: default.'

	Write-Heading '2. Migration inputs'
	[Console]::WriteLine("  $($style.Dim)Add one file or pattern per line; leave the next line empty to finish.$($style.Reset)")
	[Console]::WriteLine("  $($style.Dim)Bare filenames use $migrationRoot/.$($style.Reset)")
	[Console]::WriteLine("  $($style.Dim)Paths with / or \ remain relative to hosting, or absolute as entered.$($style.Reset)")
	$inputs = [Collections.Generic.List[string]]::new()

	while($true) {
		$hint = if($inputs.Count) { 'Enter: finish input selection.' } else { 'Enter: all *.migration files in the scheme/version directory.' }
		$inputPath = Read-Setting "Migration input $($inputs.Count + 1)" '' $hint

		if(-not $inputPath) {
			if($inputs.Count -eq 0) { $inputs.Add($migrationRoot + '/*.migration') }
			break
		}

		if($inputPath -eq '*') {
			Write-WarningMessage 'Use *.migration, or leave the first path empty to select all migration files.'
			continue
		}

		if($inputPath.EndsWith('/*', [StringComparison]::Ordinal)) {
			$inputPath = $inputPath.Substring(0, $inputPath.Length - 1) + '*.migration'
		}

		if(-not $inputPath.Contains('/') -and -not $inputPath.Contains('\')) {
			$inputPath = $migrationRoot + '/' + $inputPath
		}

		$inputs.Add($inputPath)
	}

	Write-Heading 'Execution'
	Write-Detail 'Name' $name
	if($edition) { Write-Detail 'Edition' $edition }
	Write-Detail 'Version' $version
	Write-Detail 'Runtime' "$platform-$architecture"
	Write-Detail 'Scheme' $scheme
	Write-Detail 'Output' '.migration'
	Write-Detail 'Inputs' "$($inputs.Count) pattern(s)"

	$arguments = @("--name:$name", "--edition:$edition", "--version:$version", "--platform:$platform", "--architecture:$architecture",
		"--scheme:$scheme", '--output:.migration') + $inputs.ToArray()

	$script:stage = 'Migration'
	Invoke-HostTool 'dotnet-migrate' $arguments $root

	Write-Heading 'Result'
	[Console]::WriteLine("  $($style.Green)[OK] Migration artifacts created successfully.$($style.Reset)")
}
#endregion

#region Entry point
$result = 1
$stage = 'Selection'

try {
	if($Operation -in @('Containerize', 'Migrate')) {
		Push-Location -LiteralPath $PSScriptRoot

		try {
			if($Operation -eq 'Containerize') { Invoke-Containerization } else { Invoke-Migration }
		}
		finally { Pop-Location }
	} else {
		Invoke-HostOperation
	}
}
catch [OperationCanceledException] {
	[Console]::WriteLine("  $($style.Yellow)[CANCELLED] Selection cancelled; no operation started.$($style.Reset)")
	$result = 2
}
catch {
	if($result -eq 0) { $result = 1 }

	Write-Heading 'Result'
	[Console]::WriteLine("  $($style.Red)[ERROR] $stage failed with exit code $($style.Magenta)$result$($style.Red).$($style.Reset)")
	[Console]::WriteLine("  $($style.Dim)$($_.Exception.Message)$($style.Reset)")
	Wait-Finish
}

exit $result
#endregion
