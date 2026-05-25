param(
    [string]$Root = "F:\daily-briefing",
    [string]$TaskName = "Daily Briefing Audio Generation",
    [string]$RunAt = "14:30"
)

$ErrorActionPreference = "Stop"

$audioScript = Join-Path $Root "scripts\generate_daily_audio.ps1"
if (-not (Test-Path $audioScript)) {
    throw "Audio script not found: $audioScript"
}

$action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$audioScript`""

$trigger = New-ScheduledTaskTrigger -Daily -At $RunAt
$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -MultipleInstances IgnoreNew

Register-ScheduledTask `
    -TaskName $TaskName `
    -Action $action `
    -Trigger $trigger `
    -Settings $settings `
    -Description "Generate MP3 audio from the daily briefing voice script under F:\daily-briefing." `
    -Force | Out-Null

Write-Host "Installed scheduled task: $TaskName"
Write-Host "Run time: $RunAt"
Write-Host "Script: $audioScript"

