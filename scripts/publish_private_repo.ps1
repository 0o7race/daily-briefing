param(
    [string]$Root = "F:\daily-briefing",
    [string]$Repository = "0o7race/daily-briefing",
    [string]$Branch = "main"
)

$publishScript = Join-Path $Root "scripts\publish_to_github.ps1"
& $publishScript -Root $Root -Repository $Repository -Branch $Branch
