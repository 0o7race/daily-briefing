param(
    [string]$Root = "F:\daily-briefing",
    [string]$CondaEnv = "daily-briefing-cosyvoice",
    [string]$PythonPath = "",
    [string]$Date = (Get-Date -Format "yyyy-MM-dd")
)

$ErrorActionPreference = "Stop"

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$timestamp] $Message"
    Write-Host $line

    $logDir = Join-Path $Root "logs"
    New-Item -ItemType Directory -Force -Path $logDir | Out-Null
    Add-Content -Path (Join-Path $logDir "audio.log") -Value $line -Encoding UTF8
}

$voiceFile = Join-Path $Root "briefs\$Date.voice.md"
$audioFile = Join-Path $Root "audio\$Date.mp3"
$generator = Join-Path $Root "scripts\generate_audio_cosyvoice.py"
$modelDir = Join-Path $Root "models\Fun-CosyVoice3-0.5B"
$cosyVoiceRepo = Join-Path $Root "vendor\CosyVoice"

if (-not (Test-Path $voiceFile)) {
    Write-Log "Voice script not found, skipping: $voiceFile"
    exit 0
}

if (Test-Path $audioFile) {
    Write-Log "Audio already exists, skipping: $audioFile"
    exit 0
}

if (-not (Test-Path $cosyVoiceRepo)) {
    Write-Log "CosyVoice repo not found. Run scripts\bootstrap_cosyvoice.ps1 first."
    exit 0
}

if (-not (Test-Path $modelDir)) {
    Write-Log "CosyVoice model not found. Run scripts\bootstrap_cosyvoice.ps1 first."
    exit 0
}

if (-not $PythonPath) {
    $condaExe = Get-Command conda -ErrorAction SilentlyContinue
    if (-not $condaExe) {
        Write-Log "Conda is not available on PATH and PythonPath was not provided."
        exit 0
    }

    $envInfo = conda env list | Select-String $CondaEnv | Select-Object -First 1
    if (-not $envInfo) {
        Write-Log "Conda environment not found: $CondaEnv"
        exit 0
    }

    $envPath = ($envInfo.ToString() -split '\s+')[-1]
    $PythonPath = Join-Path $envPath "python.exe"
}

if (-not (Test-Path $PythonPath)) {
    Write-Log "Python executable not found: $PythonPath"
    exit 0
}

Write-Log "Generating audio for $Date."
& $PythonPath $generator `
    --text-file $voiceFile `
    --out-mp3 $audioFile `
    --root $Root `
    --cosyvoice-repo $cosyVoiceRepo `
    --model-dir $modelDir

if ($LASTEXITCODE -ne 0) {
    Write-Log "Audio generation failed with exit code $LASTEXITCODE."
    exit $LASTEXITCODE
}

if (-not (Test-Path $audioFile)) {
    Write-Log "Audio generation finished without creating expected file: $audioFile"
    exit 1
}

Write-Log "Audio generation complete: $audioFile"
