# tts-xtts-service

A tiny **offline TTS** service using **Coqui XTTS v2** (CPU-only) with **zero-shot voice cloning**.

- Primary language: **Chinese (zh)**
- Secondary: **English (en)**
- Input: text + a reference voice wav (`voices/ref.wav`)
- Output: `wav`

> Note: CPU-only is **not real-time** for long text. Split paragraphs/sentences for best throughput.
> First start downloads large dependencies (PyTorch ~1GB+) and models; expect ~5-20 minutes depending on network.
> Recommended: mount a persistent model cache (see below) so restarts do not re-download.

## Requirements

- Docker + docker compose

## Quick start

```bash
cd ~/tts-xtts-service
mkdir -p voices output
# Put a clean 10–30s reference voice here (single speaker, no music/noise)
cp /path/to/your/ref.wav ./voices/ref.wav

docker compose up -d
docker compose logs -f
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

- `docker-compose.yml` - the service
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

By default, the container downloads model files each time a fresh container is created.
To avoid repeated downloads, mount Hugging Face + Coqui caches to the host.

Example (if you run via `run.sh`, you can extend it with these volumes):

- `~/.cache/huggingface`  (HF models)
- `~/.local/share/tts`    (Coqui TTS)

Create dirs:

```bash
mkdir -p ~/.cache/huggingface ~/.local/share/tts
```

Then add volumes to `docker run`:

```bash
-v $HOME/.cache/huggingface:/root/.cache/huggingface \
-v $HOME/.local/share/tts:/root/.local/share/tts \
```

(Inside the container we run as root; if you later switch to a non-root user, adjust paths accordingly.)
