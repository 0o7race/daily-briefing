param(
    [string]$Root = "F:\daily-briefing",
    [string]$TaskName = "Daily Briefing GitHub Publish",
    [string]$RunAt = "12:30"
)

$ErrorActionPreference = "Stop"

$publishScript = Join-Path $Root "scripts\publish_to_github.ps1"
if (-not (Test-Path $publishScript)) {
    throw "Publish script not found: $publishScript"
}

$action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$publishScript`""

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
    -Description "Commit and push generated daily briefing files from F:\daily-briefing to GitHub." `
    -Force | Out-Null

Write-Host "Installed scheduled task: $TaskName"
Write-Host "Run time: $RunAt"
Write-Host "Script: $publishScript"

