FROM python:3.10-slim

ARG PIP_INDEX_URL=https://pypi.tuna.tsinghua.edu.cn/simple
ARG PIP_TRUSTED_HOST=pypi.tuna.tsinghua.edu.cn

ENV PIP_INDEX_URL=$PIP_INDEX_URL \
    PIP_TRUSTED_HOST=$PIP_TRUSTED_HOST \
    COQUI_TOS_AGREED=1

WORKDIR /app

# Minimal runtime deps. (soundfile uses cffi; wheels are bundled)
RUN pip install --no-cache-dir --timeout 180 --retries 10 \
      -i "$PIP_INDEX_URL" --trusted-host "$PIP_TRUSTED_HOST" \
      TTS==0.22.0 fastapi uvicorn soundfile "transformers==4.41.2"

COPY app.py /app/app.py

EXPOSE 8020
CMD ["python", "/app/app.py"]
