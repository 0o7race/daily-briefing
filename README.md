# Daily Briefing

Workspace for the global science, technology, and AI daily briefing.

Generated assets should stay under this directory:

- `briefs/`: Markdown daily reports.
- `audio/`: Generated MP3 audio briefings.
- `scripts/`: Local generation and publishing scripts.
- `models/`: Local TTS model checkpoints and caches.
- `logs/`: Run logs.

The briefing workflow should not read unrelated local projects, files, or directories.
Only generated files under this workspace should be used for local publishing.

Daily local schedule:

- `10:30`: Codex automation generates the Markdown report and voice script.
- `14:30`: Windows task runs `scripts/generate_daily_audio.ps1`.
- `15:30`: Windows task runs `scripts/publish_to_github.ps1`.

Install the audio generation task once with:

```powershell
powershell -ExecutionPolicy Bypass -File F:\daily-briefing\scripts\install_audio_task.ps1
```

Install the GitHub publishing task once with:

```powershell
powershell -ExecutionPolicy Bypass -File F:\daily-briefing\scripts\install_publish_task.ps1
```

The publishing task runs after the Codex briefing automation and the audio task,
then pushes generated changes to `0o7race/daily-briefing` when GitHub
credentials are available. No public index or GitHub Pages site is generated.

Check one-time prerequisites with:

```powershell
powershell -ExecutionPolicy Bypass -File F:\daily-briefing\scripts\check_prereqs.ps1
```

Install or repair CosyVoice runtime dependencies with the CPU PyTorch build:

```powershell
powershell -ExecutionPolicy Bypass -File F:\daily-briefing\scripts\install_cosyvoice_deps.ps1 -TorchBuild cpu
```

Use `-TorchBuild cu121` only when the NVIDIA CUDA 12.1 PyTorch wheel can be
downloaded reliably. The CPU build is slower but avoids the multi-gigabyte CUDA
wheel and does not change generated voice quality.
