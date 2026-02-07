#!/usr/bin/env bash
set -euo pipefail

PORT=${PORT:-8020}
NAME=${NAME:-xtts-cpu}

mkdir -p voices output

if [ ! -f "voices/ref.wav" ]; then
  echo "[warn] voices/ref.wav not found. Put a 10–30s clean reference wav there for cloning." >&2
fi

if docker ps -a --format '{{.Names}}' | grep -qx "$NAME"; then
  docker rm -f "$NAME" >/dev/null || true
fi

# Build once, then run quickly without reinstalling deps each start.
docker build -t tts-xtts-service:cpu .

docker run -d \
  --name "$NAME" \
  -p "${PORT}:8020" \
  -e COQUI_TOS_AGREED=1 \
  -v "$PWD/voices:/voices" \
  -v "$PWD/output:/output" \
  -v "$HOME/.cache/huggingface:/root/.cache/huggingface" \
  -v "$HOME/.local/share/tts:/root/.local/share/tts" \
  tts-xtts-service:cpu

echo "started container: $NAME (port ${PORT}->8020)"
