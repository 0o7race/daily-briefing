param(
    [string]$Root = "F:\daily-briefing",
    [string]$Repository = "0o7race/daily-briefing",
    [string]$CondaEnv = "daily-briefing-cosyvoice"
)

$ErrorActionPreference = "Continue"

function Check {
    param(
        [string]$Name,
        [scriptblock]$Action
    )

    Write-Host ""
    Write-Host "== $Name =="
    try {
        & $Action
        if ($LASTEXITCODE -ne 0 -and $null -ne $LASTEXITCODE) {
            Write-Host "WARN: command exited with code $LASTEXITCODE"
        }
    } catch {
        Write-Host "WARN: $($_.Exception.Message)"
    }
}

Check "Root directory" {
    if (Test-Path $Root) {
        Write-Host "OK: $Root"
    } else {
        Write-Host "MISSING: $Root"
    }
}

Check "Git" {
    git --version
    $settings = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
    if ($settings.ProxyEnable -eq 1 -and $settings.ProxyServer) {
        $proxy = [string]$settings.ProxyServer
        if ($proxy -notmatch "=" -and $proxy -notmatch "^[a-zA-Z][a-zA-Z0-9+.-]*://") {
            $proxy = "http://$proxy"
        }
        $env:HTTP_PROXY = $proxy
        $env:HTTPS_PROXY = $proxy
        Write-Host "Using Windows proxy: $proxy"
    }
    git ls-remote "https://github.com/$Repository.git" HEAD
}

Check "Conda" {
    conda --version
    conda env list | Select-String $CondaEnv
}

Check "CosyVoice runtime" {
    $repo = Join-Path $Root "vendor\CosyVoice"
    $model = Join-Path $Root "models\Fun-CosyVoice3-0.5B"
    if (Test-Path $repo) {
        Write-Host "OK: $repo"
    } else {
        Write-Host "MISSING: $repo"
    }

    if (Test-Path $model) {
        Write-Host "OK: $model"
    } else {
        Write-Host "MISSING: $model"
    }
}

Check "Scheduled tasks" {
    Get-ScheduledTask -TaskName "Daily Briefing Audio Generation" | Select-Object TaskName,State
    Get-ScheduledTask -TaskName "Daily Briefing GitHub Publish" | Select-Object TaskName,State
}
