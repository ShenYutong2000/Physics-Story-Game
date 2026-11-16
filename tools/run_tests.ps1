param(
    [string]$GodotExe = 'D:\Game\Godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe',
    # Run only tests whose file name contains this text, e.g. -Filter hall
    [string]$Filter = '',
    # Save review screenshots here (opens a window instead of running headless).
    [string]$CaptureDir = '',
    # A test that runs longer than this is stopped and counted as failed.
    [int]$TimeoutSeconds = 180
)
# Runs every tests/*_test.gd script and exits non-zero if any fails.

$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
if (-not (Test-Path -LiteralPath $GodotExe)) { throw "Godot console executable not found: $GodotExe" }

$tests = @(Get-ChildItem -LiteralPath (Join-Path $projectRoot 'tests') -Filter '*_test.gd' |
    Where-Object { $_.Name -like "*$Filter*" } | Sort-Object Name)
if ($tests.Count -eq 0) { throw "No tests match '$Filter'." }

function Invoke-Godot([string[]]$Arguments, [int]$Seconds) {
    $outFile = [IO.Path]::GetTempFileName()
    $errFile = [IO.Path]::GetTempFileName()
    $quoted = $Arguments | ForEach-Object { if ($_ -match '\s') { '"' + $_ + '"' } else { $_ } }
    $process = Start-Process -FilePath $GodotExe -ArgumentList $quoted -NoNewWindow -PassThru `
        -RedirectStandardOutput $outFile -RedirectStandardError $errFile
    $null = $process.Handle  # cache the handle so ExitCode is available after a timed wait
    $finished = $process.WaitForExit($Seconds * 1000)
    if (-not $finished) { $process.Kill(); $process.WaitForExit() }
    $text = (Get-Content -Raw $outFile) + (Get-Content -Raw $errFile)
    Remove-Item $outFile, $errFile -ErrorAction SilentlyContinue
    [pscustomobject]@{ ExitCode = $(if ($finished) { $process.ExitCode } else { -1 }); TimedOut = -not $finished; Output = $text }
}

# Refresh the import cache so new class_name scripts and assets are registered.
$import = Invoke-Godot @('--headless', '--path', $projectRoot, '--import') 300
if ($import.ExitCode -ne 0) {
    ($import.Output -split "`r?`n" | Select-Object -Last 15) | ForEach-Object { Write-Output $_ }
    throw 'Godot import failed.'
}

$failed = @()
foreach ($test in $tests) {
    $arguments = @('--path', $projectRoot, '--script', "res://tests/$($test.Name)")
    if ($CaptureDir) {
        $arguments += @('--', "--capture-dir=$((New-Item -ItemType Directory -Force -Path $CaptureDir).FullName)")
    } else {
        $arguments = @('--headless') + $arguments
    }
    $started = Get-Date
    $result = Invoke-Godot $arguments $TimeoutSeconds
    $seconds = ((Get-Date) - $started).TotalSeconds
    if ($result.ExitCode -eq 0) {
        Write-Output ('PASS  {0,-38} {1,5:N1}s' -f $test.BaseName, $seconds)
        continue
    }
    $failed += $test.BaseName
    $reason = if ($result.TimedOut) { 'timed out' } else { "exit $($result.ExitCode)" }
    Write-Output ('FAIL  {0,-38} {1,5:N1}s  ({2})' -f $test.BaseName, $seconds, $reason)
    ($result.Output -split "`r?`n" | Where-Object { $_ -match '_FAIL|SCRIPT ERROR|Parse Error|ERROR:' } |
        Select-Object -First 8) | ForEach-Object { Write-Output "      $_" }
}

Write-Output ''
Write-Output ("{0} passed, {1} failed" -f ($tests.Count - $failed.Count), $failed.Count)
if ($failed.Count -gt 0) { exit 1 }
