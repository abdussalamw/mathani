import os
import asyncio
import json
import numpy as np
import sounddevice as sd
from fastapi import FastAPI, WebSocket
from fastapi.responses import HTMLResponse
import uvicorn
import queue
import torch
from transformers import AutoModelForSpeechSeq2Seq, AutoProcessor, pipeline

app = FastAPI()

TADABUR_MODEL_ID = "FaisaI/tadabur-Whisper-Small"
DEVICE_SAMPLE_RATE = int(sd.query_devices(sd.default.device[0], 'input')['default_samplerate'])
WHISPER_SAMPLE_RATE = 16000

print(f"\n--- تحميل نموذج تدبر القرآني ---")
processor = AutoProcessor.from_pretrained(TADABUR_MODEL_ID)
model = AutoModelForSpeechSeq2Seq.from_pretrained(TADABUR_MODEL_ID, torch_dtype=torch.float32, low_cpu_mem_usage=True)
model.eval()
asr_pipeline = pipeline(
    "automatic-speech-recognition",
    model=model,
    tokenizer=processor.tokenizer,
    feature_extractor=processor.feature_extractor,
    generate_kwargs={"language": "arabic", "task": "transcribe", "num_beams": 5},
)
print(f"✅ تدبر جاهز! (معدل الميكروفون: {DEVICE_SAMPLE_RATE} Hz)\n")

@app.get("/")
async def get():
    html_path = os.path.join(os.path.dirname(__file__), "index.html")
    with open(html_path, "r", encoding="utf-8") as f:
        return HTMLResponse(f.read())

@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()

    while True:
        command = await websocket.receive_text()

        if command == "stop_session":
            break

        if command == "record":
            # بدء التسجيل
            q = queue.Queue()
            recording = []
            stop_recording = asyncio.Event()

            def callback(indata, frames, time, status):
                recording.append(indata.copy())

            # نفتح الميكروفون بمعدله الأصلي
            stream = sd.InputStream(
                samplerate=DEVICE_SAMPLE_RATE,
                channels=1,
                dtype="float32",
                callback=callback,
            )
            stream.start()
            await websocket.send_text(json.dumps({"status": "recording"}))

            # ننتظر أمر الإيقاف
            stop_cmd = await websocket.receive_text()
            stream.stop()
            stream.close()

            if not recording:
                await websocket.send_text(json.dumps({"text": "لم يتم تسجيل أي صوت"}))
                continue

            # دمج الصوت
            full_audio = np.concatenate(recording).flatten()

            # إعادة أخذ العينات من معدل الجهاز إلى 16000 Hz إذا لزم
            if DEVICE_SAMPLE_RATE != WHISPER_SAMPLE_RATE:
                from scipy import signal
                num_samples = int(len(full_audio) * WHISPER_SAMPLE_RATE / DEVICE_SAMPLE_RATE)
                full_audio = signal.resample(full_audio, num_samples).astype(np.float32)

            amplitude = np.max(np.abs(full_audio))
            print(f"[تدبر] جارٍ تحليل الآية... (مستوى: {amplitude:.4f}, مدة: {len(full_audio)/WHISPER_SAMPLE_RATE:.1f}s)")

            await websocket.send_text(json.dumps({"status": "processing"}))

            # التحليل مع توقيت كل كلمة
            result = asr_pipeline(
                {"raw": full_audio, "sampling_rate": WHISPER_SAMPLE_RATE},
                return_timestamps="word",
            )

            chunks = result.get("chunks", [])
            full_text = result.get("text", "").strip()

            if not chunks:
                # fallback: إظهار النص دفعة واحدة
                await websocket.send_text(json.dumps({"text": full_text or "لم أتمكن من التعرف على الصوت"}))
                continue

            print(f"[النتيجة]: {full_text}")
            print(f"[الكلمات]: {len(chunks)} كلمة")

            # إرسال إشارة البدء مع النص الكامل (للمرجعية)
            await websocket.send_text(json.dumps({"full_text": full_text, "word_count": len(chunks)}))

            # إرسال كلمة بكلمة بنفس إيقاع القراءة الأصلية
            start_offset = chunks[0]["timestamp"][0] if chunks[0]["timestamp"][0] else 0
            for i, chunk in enumerate(chunks):
                word = chunk["text"].strip()
                ts_start = chunk["timestamp"][0]
                ts_end = chunk["timestamp"][1]

                if not word:
                    continue

                # حساب التأخير بين الكلمات
                if i < len(chunks) - 1:
                    next_ts = chunks[i + 1]["timestamp"][0]
                    delay = (next_ts - ts_start) if next_ts and ts_start else 0.3
                else:
                    delay = 0.5

                # إرسال الكلمة مع موضعها
                await websocket.send_text(json.dumps({
                    "word": word,
                    "index": i,
                    "total": len(chunks),
                    "done": (i == len(chunks) - 1)
                }))

                # انتظار بنفس إيقاع القراءة (بحد أقصى 1.5 ثانية بين الكلمات)
                await asyncio.sleep(min(delay, 1.5))

if __name__ == "__main__":
    import webbrowser
    from threading import Timer
    Timer(3, lambda: webbrowser.open("http://127.0.0.1:9090")).start()
    uvicorn.run(app, host="127.0.0.1", port=9090)
