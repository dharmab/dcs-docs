<#
.SYNOPSIS
    Pull the latest repo, repack Operation Infinity, and restart the DCS server.

.DESCRIPTION
    1. git pull (fast-forward only)
    2. Pack the mission to a temp file (the server stays up if this fails)
    3. Stop any running DCS server
    4. Move the packed mission to Saved Games\DCS.dcs_serverrelease\Missions
    5. Start the DCS server

    Requires git and uv on PATH. Run as the same user as the DCS server.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File scripts\deploy-operation-infinity.ps1
#>
[CmdletBinding()]
param(
    # Used only when no server is running; otherwise the running server's path is reused.
    [string]$ServerExe = "C:\Program Files\Eagle Dynamics\DCS World Server\bin\DCS_server.exe",
    [string]$WriteDir = "DCS.dcs_serverrelease",
    [string]$SavedGames = (Join-Path $env:USERPROFILE "Saved Games"),
    [int]$StopTimeoutSeconds = 60
)

$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$missionDir = Join-Path $repoRoot "missions\operation-infinity"
$missionsDir = Join-Path $SavedGames "$WriteDir\Missions"
$target = Join-Path $missionsDir "Operation Infinity.miz"
$staging = Join-Path ([IO.Path]::GetTempPath()) "Operation Infinity.miz"

function Invoke-Native {
    param([string]$Exe, [string[]]$Arguments)
    & $Exe @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "$Exe $($Arguments -join ' ') failed with exit code $LASTEXITCODE"
    }
}

Write-Host "==> Pulling $repoRoot"
Invoke-Native git @("-C", $repoRoot, "pull", "--ff-only")

Write-Host "==> Packing mission"
Invoke-Native uv @("run", "--no-project", "python", (Join-Path $missionDir "pack_mission.py"), "--output", $staging)

Write-Host "==> Stopping DCS server"
$procs = Get-Process -Name "DCS_server", "DCS" -ErrorAction SilentlyContinue |
    Where-Object { $_.Path -and $_.Path -like "*Server*" }
if ($procs) {
    $ServerExe = ($procs | Select-Object -First 1).Path
    $procs | Stop-Process -Force
    $procs | Wait-Process -Timeout $StopTimeoutSeconds
    Write-Host "    Stopped $($procs.Count) process(es)"
} else {
    Write-Host "    No running server found"
}

Write-Host "==> Installing mission to $target"
New-Item -ItemType Directory -Force -Path $missionsDir | Out-Null
Move-Item -Force -Path $staging -Destination $target

Write-Host "==> Starting $ServerExe"
if (-not (Test-Path $ServerExe)) {
    throw "Server executable not found: $ServerExe (pass -ServerExe)"
}
Start-Process -FilePath $ServerExe `
    -ArgumentList "-w", $WriteDir `
    -WorkingDirectory (Split-Path $ServerExe)

Write-Host "Done."
