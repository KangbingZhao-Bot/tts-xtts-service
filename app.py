from fastapi import FastAPI
from fastapi.responses import FileResponse
import uvicorn, os, uuid

# Coqui TTS
from TTS.api import TTS

# PyTorch >=2.6 defaults torch.load(weights_only=True) which can break XTTS checkpoints
# Allowlist XTTS config class for safe weights-only loading
import torch
from TTS.tts.configs.xtts_config import XttsConfig
from TTS.tts.models.xtts import XttsAudioConfig, XttsArgs
from TTS.config.shared_configs import BaseDatasetConfig

torch.serialization.add_safe_globals([XttsConfig, XttsAudioConfig, XttsArgs, BaseDatasetConfig])

app = FastAPI()

# Load model once at startup (CPU)
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
