import argparse
import pathlib
import re
import sys

import torch
import torchaudio


def split_text(text: str, max_chars: int = 180):
    text = re.sub(r"\s+", " ", text).strip()
    if not text:
        return []

    pieces = re.split(r"(?<=[\u3002\uff01\uff1f!?\uff1b;])", text)
    chunks = []
    current = ""
    for piece in pieces:
        piece = piece.strip()
        if not piece:
            continue
        if len(current) + len(piece) <= max_chars:
            current += piece
        else:
            if current:
                chunks.append(current)
            current = piece
    if current:
        chunks.append(current)
    return chunks


def encode_mp3(audio: torch.Tensor, sample_rate: int, out_path: pathlib.Path, bitrate: int):
    try:
        import lameenc
    except ImportError as exc:
        raise RuntimeError("lameenc is not installed; run bootstrap_cosyvoice.ps1 first.") from exc

    mono = audio.detach().cpu().squeeze()
    mono = mono.clamp(-1.0, 1.0)
    pcm = (mono * 32767.0).to(torch.int16).numpy().tobytes()

    encoder = lameenc.Encoder()
    encoder.set_bit_rate(bitrate)
    encoder.set_in_sample_rate(sample_rate)
    encoder.set_channels(1)
    encoder.set_quality(2)

    mp3 = encoder.encode(pcm) + encoder.flush()
    out_path.write_bytes(mp3)


def main():
    parser = argparse.ArgumentParser(description="Generate a Chinese daily briefing MP3 with CosyVoice3.")
    parser.add_argument("--text-file", required=True)
    parser.add_argument("--out-mp3", required=True)
    parser.add_argument("--out-wav")
    parser.add_argument("--root", default=r"F:\daily-briefing")
    parser.add_argument("--cosyvoice-repo", default=r"F:\daily-briefing\vendor\CosyVoice")
    parser.add_argument("--model-dir", default=r"F:\daily-briefing\models\Fun-CosyVoice3-0.5B")
    parser.add_argument("--prompt-audio", default=r"F:\daily-briefing\vendor\CosyVoice\asset\zero_shot_prompt.wav")
    parser.add_argument(
        "--prompt-text",
        default="You are a helpful assistant.<|endofprompt|>\u5e0c\u671b\u4f60\u4ee5\u540e\u80fd\u591f\u505a\u7684\u6bd4\u6211\u8fd8\u597d\u5466\u3002",
    )
    parser.add_argument("--bitrate", type=int, default=80)
    args = parser.parse_args()

    cosyvoice_repo = pathlib.Path(args.cosyvoice_repo)
    if not cosyvoice_repo.exists():
        raise FileNotFoundError(f"CosyVoice repo not found: {cosyvoice_repo}")

    matcha_path = cosyvoice_repo / "third_party" / "Matcha-TTS"
    sys.path.insert(0, str(cosyvoice_repo))
    sys.path.insert(0, str(matcha_path))

    from cosyvoice.cli.cosyvoice import AutoModel

    text = pathlib.Path(args.text_file).read_text(encoding="utf-8")
    chunks = split_text(text)
    if not chunks:
        raise ValueError("Input text is empty after normalization.")

    model = AutoModel(model_dir=args.model_dir)

    all_audio = []
    for chunk in chunks:
        for result in model.inference_zero_shot(
            chunk,
            args.prompt_text,
            args.prompt_audio,
            stream=False,
        ):
            all_audio.append(result["tts_speech"])

    if not all_audio:
        raise RuntimeError("CosyVoice returned no audio chunks.")

    audio = torch.cat(all_audio, dim=-1)
    out_mp3 = pathlib.Path(args.out_mp3)
    out_mp3.parent.mkdir(parents=True, exist_ok=True)
    encode_mp3(audio, model.sample_rate, out_mp3, args.bitrate)

    if args.out_wav:
        out_wav = pathlib.Path(args.out_wav)
        out_wav.parent.mkdir(parents=True, exist_ok=True)
        torchaudio.save(str(out_wav), audio.cpu(), model.sample_rate)

    print(f"Wrote {out_mp3}")


if __name__ == "__main__":
    main()
