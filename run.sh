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
  --name "" \
  -p "${PORT}:8020" \
  -v "$PWD/voices:/voices" \
  -v "$PWD/output:/output" \
  -v "$HOME/.cache/huggingface:/root/.cache/huggingface" \
  -v "$HOME/.local/share/tts:/root/.local/share/tts" \  tts-xtts-service:cpu

echo "started container: $NAME (port ${PORT}->8020)"
