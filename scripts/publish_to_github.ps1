param(
    [string]$Root = "F:\daily-briefing",
    [string]$Repository = "0o7race/daily-briefing",
    [string]$Branch = "main"
)

$ErrorActionPreference = "Stop"

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$timestamp] $Message"
    Write-Host $line

    $logDir = Join-Path $Root "logs"
    New-Item -ItemType Directory -Force -Path $logDir | Out-Null
    Add-Content -Path (Join-Path $logDir "publish.log") -Value $line -Encoding UTF8
}

function Use-WindowsProxyIfAvailable {
    try {
        $settings = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
        if ($settings.ProxyEnable -ne 1 -or -not $settings.ProxyServer) {
            return
        }

        $proxyServer = [string]$settings.ProxyServer
        $proxy = $null

        if ($proxyServer -match "=") {
            $entries = @{}
            foreach ($part in ($proxyServer -split ";")) {
                $kv = $part -split "=", 2
                if ($kv.Length -eq 2) {
                    $entries[$kv[0].Trim().ToLowerInvariant()] = $kv[1].Trim()
                }
            }
            if ($entries.ContainsKey("https")) {
                $proxy = $entries["https"]
            } elseif ($entries.ContainsKey("http")) {
                $proxy = $entries["http"]
            }
        } else {
            $proxy = $proxyServer
        }

        if ($proxy) {
            if ($proxy -notmatch "^[a-zA-Z][a-zA-Z0-9+.-]*://") {
                $proxy = "http://$proxy"
            }
            $env:HTTP_PROXY = $proxy
            $env:HTTPS_PROXY = $proxy
            Write-Log "Using Windows proxy for git: $proxy"
        }
    } catch {
        Write-Log "Could not read Windows proxy settings: $($_.Exception.Message)"
    }
}

Use-WindowsProxyIfAvailable

if (-not (Test-Path $Root)) {
    throw "Root directory does not exist: $Root"
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw "git is not available on PATH."
}

$remoteUrl = "https://github.com/$Repository.git"

if (-not (Test-Path (Join-Path $Root ".git"))) {
    Write-Log "Initializing git repository."
    git -C $Root init | Out-Null
}

$remoteNames = git -C $Root remote
if ($remoteNames -notcontains "origin") {
    Write-Log "Adding origin remote: $remoteUrl"
    git -C $Root remote add origin $remoteUrl
} else {
    $currentRemote = git -C $Root remote get-url origin
    if ($currentRemote -ne $remoteUrl) {
        Write-Log "Updating origin remote: $remoteUrl"
        git -C $Root remote set-url origin $remoteUrl
    }
}

$remoteHead = git -C $Root ls-remote --heads origin $Branch
if ($remoteHead) {
    Write-Log "Aligning local branch with origin/$Branch."
    git -C $Root fetch --depth 1 origin $Branch | Out-Null
    git -C $Root checkout -B $Branch | Out-Null
    git -C $Root reset --mixed FETCH_HEAD | Out-Null
} else {
    git -C $Root checkout -B $Branch | Out-Null
}

$trackedPaths = @(
    "README.md",
    ".gitignore",
    "config",
    "scripts",
    "briefs",
    "audio"
)

git -C $Root add -- $trackedPaths

$changes = git -C $Root status --porcelain
if (-not $changes) {
    Write-Log "No changes to publish."
    exit 0
}

$today = Get-Date -Format "yyyy-MM-dd"
$message = "Publish daily briefing updates $today"

Write-Log "Committing changes."
git -C $Root commit -m $message | Out-Null

Write-Log "Pushing to GitHub."
git -C $Root push -u origin $Branch
Write-Log "Publish complete."
