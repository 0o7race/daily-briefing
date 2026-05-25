param(
    [string]$Root = "F:\daily-briefing",
    [ValidateSet("huggingface", "modelscope")]
    [string]$Provider = "huggingface",
    [string]$CondaEnv = "daily-briefing-cosyvoice",
    [ValidateSet("cpu", "cu121")]
    [string]$TorchBuild = "cpu"
)

$ErrorActionPreference = "Stop"

$CosyVoiceRepo = Join-Path $Root "vendor\CosyVoice"
$ModelDir = Join-Path $Root "models\Fun-CosyVoice3-0.5B"

New-Item -ItemType Directory -Force -Path $Root | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $Root "vendor") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $Root "models") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $Root "logs") | Out-Null

if (-not (Get-Command conda -ErrorAction SilentlyContinue)) {
    throw "Conda is required for CosyVoice. Install Miniconda or Anaconda first, then rerun this script."
}

if (-not (Test-Path $CosyVoiceRepo)) {
    git clone --recursive https://github.com/FunAudioLLM/CosyVoice.git $CosyVoiceRepo
} else {
    git -C $CosyVoiceRepo pull --ff-only
    git -C $CosyVoiceRepo submodule update --init --recursive
}

$envList = conda env list | Out-String
if ($envList -notmatch "^\s*$CondaEnv\s") {
    conda create -n $CondaEnv -y python=3.10
}

$depsScript = Join-Path $Root "scripts\install_cosyvoice_deps.ps1"
if (Test-Path $depsScript) {
    & $depsScript -Root $Root -CondaEnv $CondaEnv -TorchBuild $TorchBuild
} else {
    conda run -n $CondaEnv python -m pip install -r (Join-Path $CosyVoiceRepo "requirements.txt")
    conda run -n $CondaEnv python -m pip install huggingface_hub modelscope lameenc
}

if ($Provider -eq "modelscope") {
    conda run -n $CondaEnv python -c "from modelscope import snapshot_download; snapshot_download('FunAudioLLM/Fun-CosyVoice3-0.5B-2512', local_dir=r'$ModelDir')"
} else {
    conda run -n $CondaEnv python -c "from huggingface_hub import snapshot_download; snapshot_download('FunAudioLLM/Fun-CosyVoice3-0.5B-2512', local_dir=r'$ModelDir')"
}

Write-Host "CosyVoice setup complete."
Write-Host "Repo:  $CosyVoiceRepo"
Write-Host "Model: $ModelDir"
