param(
    [string]$Root = "F:\daily-briefing",
    [string]$CondaEnv = "daily-briefing-cosyvoice",
    [string]$PythonPath = "",
    [ValidateSet("cpu", "cu121")]
    [string]$TorchBuild = "cpu"
)

$ErrorActionPreference = "Stop"

function Run-Pip {
    param([string[]]$Arguments)
    & $PythonPath -m pip @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "pip failed: $($Arguments -join ' ')"
    }
}

$requirements = Join-Path $Root "vendor\CosyVoice\requirements.txt"
if (-not (Test-Path $requirements)) {
    throw "CosyVoice requirements not found: $requirements"
}

if (-not $PythonPath) {
    $condaExe = Get-Command conda -ErrorAction SilentlyContinue
    if (-not $condaExe) {
        throw "conda is not available and PythonPath was not provided."
    }

    $envInfo = conda env list | Select-String $CondaEnv | Select-Object -First 1
    if (-not $envInfo) {
        throw "Conda environment not found: $CondaEnv"
    }

    $envPath = ($envInfo.ToString() -split '\s+')[-1]
    $PythonPath = Join-Path $envPath "python.exe"
}

if (-not (Test-Path $PythonPath)) {
    throw "Python executable not found: $PythonPath"
}

$generated = Join-Path $Root "config\cosyvoice-runtime-requirements.txt"
New-Item -ItemType Directory -Force -Path (Split-Path $generated) | Out-Null

Get-Content $requirements |
    Where-Object {
        $_ -notmatch '^--extra-index-url' -and
        $_ -notmatch '^torch==' -and
        $_ -notmatch '^torchaudio=='
    } |
    Set-Content -Path $generated -Encoding UTF8

Run-Pip @("install", "setuptools<81", "wheel", "build")
Run-Pip @("install", "--no-cache-dir", "--no-build-isolation", "openai-whisper==20231117")

if ($TorchBuild -eq "cpu") {
    Run-Pip @(
        "install",
        "--no-cache-dir",
        "--index-url", "https://download.pytorch.org/whl/cpu",
        "torch==2.3.1+cpu",
        "torchaudio==2.3.1+cpu"
    )
} else {
    Run-Pip @(
        "install",
        "--no-cache-dir",
        "--index-url", "https://download.pytorch.org/whl/cu121",
        "torch==2.3.1+cu121",
        "torchaudio==2.3.1+cu121"
    )
}

Run-Pip @("install", "-r", $generated)
Run-Pip @("install", "lameenc")

Write-Host "CosyVoice dependencies installed with Torch build: $TorchBuild"
Write-Host "Python: $PythonPath"
Write-Host "Filtered requirements: $generated"
