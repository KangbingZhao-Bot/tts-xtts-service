#!/usr/bin/env bash
set -euo pipefail

PORT=${PORT:-8020}
NAME=${NAME:-xtts-cpu}

# If you're in CN or your PyPI is slow, you can override these:
PIP_INDEX_URL_DEFAULT="https://pypi.tuna.tsinghua.edu.cn/simple"
PIP_TRUSTED_HOST_DEFAULT="pypi.tuna.tsinghua.edu.cn"

PIP_INDEX_URL=${PIP_INDEX_URL:-$PIP_INDEX_URL_DEFAULT}
PIP_TRUSTED_HOST=${PIP_TRUSTED_HOST:-$PIP_TRUSTED_HOST_DEFAULT}

mkdir -p voices output

if [ ! -f "voices/ref.wav" ]; then
  echo "[warn] voices/ref.wav not found. Put a 10–30s clean reference wav there for cloning." >&2
fi

if docker ps -a --format '{{.Names}}' | grep -qx "$NAME"; then
  docker rm -f "$NAME" >/dev/null || true
fi

docker run -d \
  --name "$NAME" \
  -p "${PORT}:8020" \
  -v "$PWD/voices:/voices" \
  -v "$PWD/output:/output" \
  -v "$HOME/.cache/huggingface:/root/.cache/huggingface" \
  -v "$HOME/.local/share/tts:/root/.local/share/tts" \
  -e PIP_INDEX_URL="$PIP_INDEX_URL" \
  -e PIP_TRUSTED_HOST="$PIP_TRUSTED_HOST" \
  python:3.10-slim \
  bash -lc "
    pip install --no-cache-dir --timeout 180 --retries 10 -i \"$PIP_INDEX_URL\" --trusted-host \"$PIP_TRUSTED_HOST\" \
      TTS==0.22.0 fastapi uvicorn soundfile &&
    python - << 'PY'
from fastapi import FastAPI
from fastapi.responses import FileResponse
import uvicorn, os, uuid
from TTS.api import TTS

app = FastAPI()

tts = TTS('tts_models/multilingual/multi-dataset/xtts_v2').to('cpu')

@app.get('/health')
def health():
    return {'ok': True}

@app.post('/tts')
def synth(text: str, ref: str = '/voices/ref.wav', lang: str = 'zh'):
    out = f'/output/{uuid.uuid4().hex}.wav'
    tts.tts_to_file(text=text, speaker_wav=ref, language=lang, file_path=out)
    return FileResponse(out, media_type='audio/wav', filename=os.path.basename(out))

if __name__ == '__main__':
    uvicorn.run(app, host='0.0.0.0', port=8020)
PY
  "

echo "started container: $NAME (port ${PORT}->8020)"
