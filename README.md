# tts-xtts-service

A tiny **offline TTS** HTTP service using **Coqui XTTS v2** (CPU-only) with **zero-shot voice cloning**.

- Primary language: **Chinese (zh)**
- Secondary: **English (en)**
- Input: text + a reference voice wav (`voices/ref.wav`)
- Output: `wav`

> CPU-only is **not real-time** for long text. Split paragraphs/sentences for better throughput.

## Requirements

- Docker

## Quick start

```bash
cd ~/tts-xtts-service
mkdir -p voices output
# Put a clean 10–30s reference voice here (single speaker, no music/noise)
cp /path/to/your/ref.wav ./voices/ref.wav

./run.sh
```

Health check:

```bash
curl -s http://127.0.0.1:8020/health
```

## Generate speech

Chinese:

```bash
curl -X POST "http://127.0.0.1:8020/tts?text=你好，我是你的本地语音助手&lang=zh" \
  --output out.wav
```

English:

```bash
curl -X POST "http://127.0.0.1:8020/tts?text=Hello%20world&lang=en" \
  --output out-en.wav
```

Use a different reference wav (path inside container):

```bash
curl -X POST "http://127.0.0.1:8020/tts?text=测试一下&lang=zh&ref=/voices/ref.wav" \
  --output out.wav
```

## Files

- `Dockerfile` - builds the runtime image (deps installed at build time)
- `app.py` - FastAPI app
- `run.sh` - build+run helper
- `voices/ref.wav` - your reference voice (not committed)
- `output/` - generated wav files (not committed)

## Tips for better cloning (no finetuning)

- Use **clean, dry** audio: no BGM, no reverb, no echo.
- 10–30 seconds is a sweet spot.
- If your reference is too loud/quiet, normalize it first (optional):

```bash
ffmpeg -y -i voices/ref.wav -af loudnorm voices/ref.norm.wav
```

Then use `ref=/voices/ref.norm.wav`.

## Persistent cache (recommended)

This service mounts the host caches so model downloads persist across container recreations:

- `~/.cache/huggingface`  (HF models)
- `~/.local/share/tts`    (Coqui TTS)

Create dirs:

```bash
mkdir -p ~/.cache/huggingface ~/.local/share/tts
```
