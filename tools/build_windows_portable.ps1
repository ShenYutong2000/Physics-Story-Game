param(
    [string]$GodotExe = 'D:\Game\Godot-4.7.2\Godot_v4.7.2-stable_win64.exe'
)

$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$gameFolder = Join-Path $projectRoot 'build\windows'
$consoleExe = $GodotExe -replace '_win64\.exe$', '_win64_console.exe'
if (-not (Test-Path -LiteralPath $GodotExe)) { throw "Godot executable not found: $GodotExe" }
if (-not (Test-Path -LiteralPath $consoleExe)) { throw "Godot console executable not found: $consoleExe" }
New-Item -ItemType Directory -Path $gameFolder -Force | Out-Null
$pack = Join-Path $gameFolder 'FootnotesToTheWorld.pck'
& $consoleExe --headless --quiet --path $projectRoot --export-pack 'Windows Desktop' $pack
if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $pack) -or (Get-Item -LiteralPath $pack).Length -lt 1MB) {
    throw 'Godot did not produce a valid game pack.'
}
& $consoleExe --headless --main-pack $pack --quit-after 5
if ($LASTEXITCODE -ne 0) { throw 'The exported game pack did not start.' }
Copy-Item -LiteralPath $GodotExe -Destination (Join-Path $gameFolder 'FootnotesToTheWorld.exe') -Force
Copy-Item -LiteralPath (Join-Path $projectRoot 'GODOT_LICENSE.txt') -Destination (Join-Path $gameFolder 'GODOT_LICENSE.txt') -Force
@'
@echo off
cd /d "%~dp0"
"%~dp0FootnotesToTheWorld.exe" --main-pack "%~dp0FootnotesToTheWorld.pck"
'@ | Set-Content -LiteralPath (Join-Path $gameFolder 'Play Footnotes.cmd') -Encoding Ascii
@'
FOOTNOTES TO THE WORLD - Prologue + Chapter I

Double-click "Play Footnotes.cmd" to start.
The first launch may take a few seconds. Settings are on the title screen;
press S while paused to open the same menu. This build uses Godot 4.7.2.
Story progress is stored in Godot's per-user data folder.

Godot license: see GODOT_LICENSE.txt.
'@ | Set-Content -LiteralPath (Join-Path $gameFolder 'README-WINDOWS.txt') -Encoding Ascii
$hashLines = @('FootnotesToTheWorld.exe', 'FootnotesToTheWorld.pck') | ForEach-Object {
    $item = Join-Path $gameFolder $_
    (Get-FileHash -LiteralPath $item -Algorithm SHA256).Hash + '  ' + $_
}
$hashLines | Set-Content -LiteralPath (Join-Path $gameFolder 'SHA256SUMS.txt') -Encoding Ascii

$archive = Join-Path $projectRoot 'build\FootnotesToTheWorld-Windows.zip'
Compress-Archive -LiteralPath (Get-ChildItem -LiteralPath $gameFolder -File | ForEach-Object FullName) -DestinationPath $archive -Force
Write-Output "WINDOWS_PACKAGE_OK: $archive"
