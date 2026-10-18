#region 初始设置
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

if($useColor)
{
	$style.Heading = "$escape[1;96m"
	$style.Cyan = "$escape[96m"
	$style.Green = "$escape[92m"
	$style.Yellow = "$escape[33m"
	$style.Red = "$escape[31m"
	$style.Magenta = "$escape[95m"
	$style.Dim = "$escape[90m"
	$style.Reset = "$escape[0m"
}
#endregion

#region 交互输出
function Write-Heading([string]$Text)
{
	[Console]::WriteLine()
	[Console]::WriteLine("  $($style.Heading)$Text$($style.Reset)")
	[Console]::WriteLine("  $($style.Dim)------------------------------------------------------------$($style.Reset)")
}

function Write-Detail([string]$Label, [string]$Value)
{
	[Console]::WriteLine(('  {0}{1,-16}{2}{3}{4}' -f $style.Dim, ($Label + ':'), $style.Cyan, $Value, $style.Reset))
}

function Write-WarningMessage([string]$Text)
{
	[Console]::WriteLine("  $($style.Yellow)[WARN] $Text$($style.Reset)")
}

function Wait-Finish
{
	if(-not $interactive)
	{
		return
	}

	[Console]::WriteLine()
	[Console]::WriteLine("  $($style.Dim)Press any key to finish.$($style.Reset)")
	[void][Console]::ReadKey($true)
}
#endregion

#region 输入设置
function Read-Setting([string]$Label, [string]$Default = '', [string]$Hint = '', [switch]$AllowBack)
{
	if($interactive)
	{
		# Reserve the hint line before returning the cursor to the input field.
		[Console]::Write("  $($style.Cyan)${Label}: $($style.Reset)")
		$left = [Console]::CursorLeft
		[Console]::WriteLine()
		[Console]::WriteLine("  $($style.Dim)$Hint$($style.Reset)")
		$top = [Math]::Max(0, [Console]::CursorTop - 2)
		[Console]::SetCursorPosition($left, $top)

		try
		{
			if($AllowBack)
			{
				$buffer = [Text.StringBuilder]::new()

				while($true)
				{
					$key = [Console]::ReadKey($true)

					if($key.Key -eq 'Escape')
					{
						[Console]::WriteLine()

						return $null
					}

					if($key.Key -eq 'Enter')
					{
						[Console]::WriteLine()
						break
					}

					if($key.Key -eq 'Backspace')
					{
						if($buffer.Length -gt 0)
						{
							[void]$buffer.Remove($buffer.Length - 1, 1)
							[Console]::Write("`b `b")
						}

						continue
					}

					if(-not [char]::IsControl($key.KeyChar))
					{
						[void]$buffer.Append($key.KeyChar)
						[Console]::Write($key.KeyChar)
					}
				}

				$answer = $buffer.ToString()
			}
			else
			{
				$answer = [Console]::ReadLine()
			}
		}
		finally
		{
			[Console]::SetCursorPosition(0, [Math]::Max([Console]::CursorTop, $top + 2))
		}
	}
	else
	{
		[Console]::WriteLine("  ${Label}:")

		if($Hint)
		{
			[Console]::WriteLine("  $Hint")
		}

		$answer = [Console]::ReadLine()
	}

	[Console]::WriteLine()

	if($null -eq $answer)
	{
		throw [OperationCanceledException]::new()
	}

	$answer = $answer.Trim()

	if($answer.Length -ge 2 -and $answer.StartsWith('"') -and $answer.EndsWith('"'))
	{
		$answer = $answer.Substring(1, $answer.Length - 2).Trim()
	}

	if($AllowBack -and $answer -ieq 'esc')
	{
		return $null
	}

	if($answer.Length -eq 0)
	{
		return $Default
	}

	return $answer
}

function Read-DeploymentScheme([string]$Label = 'Scheme')
{
	$directory = Join-Path $PSScriptRoot '.deploy'
	$schemes = @(Get-ChildItem -LiteralPath $directory -Directory -Force |
		Where-Object { -not $_.Name.StartsWith('.') } | Sort-Object Name | ForEach-Object { $_.Name })

	if($schemes.Count -eq 0)
	{
		throw "No deployment schemes found in $directory."
	}

	$default = if($schemes -contains 'default') { 'default' } else { $schemes[0] }

	return Read-Choice $Label $schemes $default "Choose a directory from hosting/.deploy. Default: $default."
}

function Get-HostingFramework
{
	$path = Join-Path $PSScriptRoot '.env'
	$framework = ''

	# Read only the root-level literal shared by the host builds and packaging.
	foreach($line in Get-Content -LiteralPath $path)
	{
		if($line -match '^\s*\[')
		{
			break
		}

		if($line -match '^\s*framework\s*=(.*)$')
		{
			$framework = $Matches[1].Trim()
		}
	}

	if($framework -notmatch '^net(?:standard|coreapp)?\d+(?:\.\d+)*(?:-[a-zA-Z0-9.]+)?$')
	{
		throw "Define a literal target framework in the root-level framework entry of $path."
	}

	return $framework
}

function Read-DeploymentSettings
{
	Write-Heading '2. Deployment settings'

	$scheme = Read-DeploymentScheme
	$environments = @('Development', 'Test', 'Production') | ForEach-Object {
		[pscustomobject]@{ Value = $_.ToLowerInvariant(); Label = $_ }
	}
	$defaultEnvironment = if($env:Environment -in $environments.Value) { $env:Environment } else { 'development' }
	$environment = (Read-Menu 'Environment' $environments $defaultEnvironment "Default: $defaultEnvironment.").Value
	$network = Read-Choice 'Network' @('internal', 'external') 'internal' 'Choose the network used by this deployment.'
	$env:Environment = $environment

	return [pscustomobject]@{
		Scheme = $scheme
		Environment = $environment
		Network = $network
	}
}
#endregion

#region 菜单选择
function Format-MenuRow($Row, [int]$Index, [bool[]]$Checked, [switch]$Multiple)
{
	$indent = '  ' * [int]$Row.Item.Depth

	if($Row.Number -eq 0)
	{
		return '      {0}{1}' -f $indent, $Row.Item.Label
	}

	$marker = if($Row.Number -eq $Index + 1) { '> ' } else { '  ' }
	$check = if($Multiple)
	{
		if($Checked[$Row.Number - 1]) { '[x] ' } else { '[ ] ' }
	}
	else { '' }

	return '    {0}{1}{2}{3}. {4}' -f $marker, $indent, $check, $Row.Number, $Row.Item.Label
}

function Read-Menu([string]$Label, [object[]]$Items, [string]$Default, [string]$Hint = '', [switch]$Multiple, [switch]$AllowBack)
{
	$choices = [Collections.Generic.List[object]]::new()
	$positions = [Collections.Generic.List[int]]::new()
	$display = [Collections.Generic.List[object]]::new()

	foreach($item in $Items)
	{
		$number = 0

		if(-not $item.Group)
		{
			$positions.Add($display.Count)
			$choices.Add($item)
			$number = $choices.Count
		}

		$display.Add([pscustomobject]@{ Item = $item; Number = $number })
	}

	if($choices.Count -eq 0)
	{
		throw 'There are no choices available.'
	}

	[Console]::WriteLine("  $($style.Cyan)$Label$($style.Reset)")

	if($Hint)
	{
		[Console]::WriteLine("  $($style.Dim)$Hint$($style.Reset)")
	}

	$index = 0
	$checked = [bool[]]::new($choices.Count)

	for($row = 0; $row -lt $choices.Count; $row++)
	{
		if($choices[$row].Value -eq $Default)
		{
			$index = $row
			break
		}
	}

	if(-not $interactive)
	{
		foreach($row in $display)
		{
			[Console]::WriteLine((Format-MenuRow $row -1 $checked -Multiple:$Multiple))
		}

		while($true)
		{
			$defaultAnswer = if($Multiple) { '' } else { [string]($index + 1) }
			$inputHint = if($Multiple)
			{
				'Numbers separated by commas, or a listed path. Enter: no hosts. Esc: cancel.'
			}
			else
			{
				"Number or listed value. Enter: $($index + 1). Esc: back/cancel."
			}
			$answer = Read-Setting 'Option' $defaultAnswer $inputHint

			if($answer -ieq 'esc')
			{
				if($AllowBack)
				{
					return $null
				}

				throw [OperationCanceledException]::new()
			}

			if($Multiple -and $answer.Length -eq 0)
			{
				return
			}

			# A complete value is checked first so a literal path may contain commas.
			$answers = @($answer)

			if($Multiple -and -not ($choices | Where-Object { $_.Value -ieq $answer }))
			{
				$answers = @($answer.Split(',') | ForEach-Object { $_.Trim() })
			}

			$selected = [Collections.Generic.HashSet[int]]::new()
			$valid = $true

			foreach($value in $answers)
			{
				$found = $false

				for($row = 0; $row -lt $choices.Count; $row++)
				{
					if($value -eq [string]($row + 1) -or $value -ieq $choices[$row].Value)
					{
						[void]$selected.Add($row)
						$found = $true
						break
					}
				}

				if(-not $found)
				{
					$valid = $false
				}
			}

			if($valid)
			{
				for($row = 0; $row -lt $choices.Count; $row++)
				{
					if($selected.Contains($row))
					{
						$choices[$row]
					}
				}

				return
			}

			Write-WarningMessage 'Invalid selection. Choose one of the numbered options; group headings cannot be selected.'
		}
	}

	$keys = if($Multiple)
	{
		'Up/Down: move   Space: toggle   Enter: confirm   Esc: cancel'
	}
	else
	{
		'Up/Down: move   Enter: confirm   Esc: back/cancel'
	}
	[Console]::WriteLine("    $($style.Dim)$keys$($style.Reset)")

	$rows = [Math]::Min($display.Count, [Math]::Max(1, [Math]::Min(10, [Console]::WindowHeight - 6)))

	for($row = 0; $row -lt $rows; $row++)
	{
		[Console]::WriteLine()
	}

	$top = [Console]::CursorTop - $rows
	$foreground = [Console]::ForegroundColor
	$background = [Console]::BackgroundColor
	$cursor = [Console]::CursorVisible
	$first = 0

	try
	{
		[Console]::CursorVisible = $false

		while($true)
		{
			$position = $positions[$index]

			if($position -lt $first)
			{
				$first = $position
			}

			if($position -ge $first + $rows)
			{
				$first = $position - $rows + 1
			}

			[Console]::SetCursorPosition(0, $top)
			$width = [Math]::Max(1, [Console]::BufferWidth - 1)

			for($row = 0; $row -lt $rows; $row++)
			{
				$current = $first + $row

				if($useColor)
				{
					[Console]::ForegroundColor = if($display[$current].Number -eq 0) { 'DarkGray' } else { $foreground }
					[Console]::BackgroundColor = $background

					if($current -eq $position)
					{
						[Console]::ForegroundColor = 'White'
						[Console]::BackgroundColor = 'DarkCyan'
					}
				}

				$line = Format-MenuRow $display[$current] $index $checked -Multiple:$Multiple

				if($line.Length -gt $width)
				{
					$line = $line.Substring(0, $width)
				}

				[Console]::WriteLine($line.PadRight($width))
			}

			if($useColor)
			{
				[Console]::ForegroundColor = $foreground
				[Console]::BackgroundColor = $background
			}

			switch([Console]::ReadKey($true).Key)
			{
				'UpArrow' { $index = ($index + $choices.Count - 1) % $choices.Count }
				'DownArrow' { $index = ($index + 1) % $choices.Count }
				'Home' { $index = 0 }
				'End' { $index = $choices.Count - 1 }
				'Spacebar'
				{
					if($Multiple)
					{
						$checked[$index] = -not $checked[$index]
					}
				}
				'Enter'
				{
					if($Multiple)
					{
						for($row = 0; $row -lt $choices.Count; $row++)
						{
							if($checked[$row])
							{
								$choices[$row]
							}
						}

						return
					}

					return $choices[$index]
				}
				'Escape'
				{
					if($AllowBack)
					{
						return $null
					}

					throw [OperationCanceledException]::new()
				}
			}
		}
	}
	finally
	{
		if($useColor)
		{
			[Console]::ForegroundColor = $foreground
			[Console]::BackgroundColor = $background
		}

		[Console]::CursorVisible = $cursor
		[Console]::SetCursorPosition(0, $top + $rows)
		[Console]::WriteLine()
	}
}

function Read-Choice([string]$Label, [string[]]$Values, [string]$Default, [string]$Hint = '')
{
	$choices = @($Values | ForEach-Object { [pscustomobject]@{ Value = $_; Label = $_ } })

	return (Read-Menu $Label $choices $Default $Hint).Value
}
#endregion

#region 宿主发现
function Get-HostProject([string]$Directory, [string]$RelativePath)
{
	if(-not (Test-Path -LiteralPath (Join-Path $Directory '.deploy') -PathType Leaf))
	{
		return
	}

	foreach($type in @('Daemon', 'Terminal', 'Web'))
	{
		if(Test-Path -LiteralPath (Join-Path $Directory "Zongsoft.Hosting.$type.csproj") -PathType Leaf)
		{
			return [pscustomobject]@{
				Value = $RelativePath.Replace('\', '/')
				Label = if($RelativePath -eq '.') { (Get-Item -LiteralPath $Directory).Name } else { ($RelativePath.Replace('\', '/') -split '/')[-1] }
				Directory = $Directory
				Type = $type
			}
		}
	}
}

function Get-HostProjects([string]$Root)
{
	$pending = [Collections.Generic.Queue[object]]::new()
	$pending.Enqueue([pscustomobject]@{ Directory = $Root; RelativePath = '.' })

	while($pending.Count -gt 0)
	{
		$current = $pending.Dequeue()
		$project = Get-HostProject $current.Directory $current.RelativePath

		if($null -ne $project)
		{
			$project

			continue
		}

		foreach($directory in Get-ChildItem -LiteralPath $current.Directory -Directory | Sort-Object Name)
		{
			if($directory.Name.StartsWith('.') -or $directory.Name -in @('bin', 'obj', 'packages', 'node_modules') -or
				($directory.Attributes -band [IO.FileAttributes]::ReparsePoint))
			{
					continue
			}

			$relative = if($current.RelativePath -eq '.') { $directory.Name } else { $current.RelativePath + '/' + $directory.Name }
			$pending.Enqueue([pscustomobject]@{ Directory = $directory.FullName; RelativePath = $relative })
		}
	}
}

function Get-HostMenuItems([object[]]$Projects, [int]$Depth = 0)
{
	# Sort each directory level independently; group headings never become choices.
	$groups = $Projects | Group-Object { $_.Value.Split('/')[$Depth] } | Sort-Object Name

	foreach($group in $groups)
	{
		$project = $group.Group[0]

		if($project.Value.Split('/').Length -gt $Depth + 1)
		{
			[pscustomobject]@{ Label = $group.Name; Depth = $Depth; Group = $true }
			Get-HostMenuItems $group.Group ($Depth + 1)
		}
		else
		{
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

function Read-HostProject([string]$Root)
{
	Write-Heading '1. Host project'

	if($env:ZONGSOFT_HOSTING_SOURCE)
	{
		$requested = $env:ZONGSOFT_HOSTING_SOURCE
		$directory = if([IO.Path]::IsPathRooted($requested)) { $requested } else { Join-Path $root $requested }
		$directory = [IO.Path]::GetFullPath($directory)
		$selectedHost = Get-HostProject $directory $requested

		if($null -eq $selectedHost)
		{
			throw "Source must contain .deploy and a Zongsoft host project: $requested"
		}
	}
	else
	{
		$projects = @(Get-HostProjects $root)

		if($projects.Count -eq 0)
		{
			throw "No host projects found in $root. Expected .deploy and Zongsoft.Hosting.Daemon/Terminal/Web.csproj."
		}

		$selectedHost = Read-Menu 'Source' @(Get-HostMenuItems $projects) 'daemon' 'Choose a host project from the current directory.'
	}

	Write-Detail 'Source' $selectedHost.Value
	Write-Detail 'Host' $selectedHost.Type

	return $selectedHost
}
#endregion

#region 执行控制
function Invoke-HostTool([string]$Command, [string[]]$Arguments, [string]$Directory)
{
	Push-Location -LiteralPath $Directory

	try
	{
		# Invoke the native tool with separate arguments; never evaluate a command string.
		& $Command @Arguments
		$script:result = $LASTEXITCODE
	}
	finally { Pop-Location }

	if($script:result -ne 0)
	{
		throw "$Command failed."
	}
}

function Invoke-HostingOperation([scriptblock]$Action, [string]$Directory = '')
{
	$script:result = 1
	$script:stage = 'Selection'
	$originalEnvironment = $env:Environment

	try
	{
		if($Directory)
		{
			Push-Location -LiteralPath $Directory

			try { & $Action }
			finally { Pop-Location }
		}
		else
		{
			& $Action
		}
	}
	catch [OperationCanceledException]
	{
		[Console]::WriteLine("  $($style.Yellow)[CANCELLED] Selection cancelled; no operation started.$($style.Reset)")
		$script:result = 2
	}
	catch
	{
		if($script:result -eq 0)
		{
			$script:result = 1
		}

		Write-Heading 'Result'
		[Console]::WriteLine("  $($style.Red)[ERROR] $stage failed with exit code $($style.Magenta)$result$($style.Red).$($style.Reset)")
		[Console]::WriteLine("  $($style.Dim)$($_.Exception.Message)$($style.Reset)")
		Wait-Finish
	}
	finally
	{
		$env:Environment = $originalEnvironment
	}
}
#endregion
