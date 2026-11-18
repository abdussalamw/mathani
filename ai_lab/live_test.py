import os
import sys
import numpy as np
import onnxruntime as ort
from transformers import AutoTokenizer, AutoProcessor
import sounddevice as sd
import queue

# إعداد المسارات
MODEL_DIR = "onnx_model"
ENCODER_PATH = os.path.join(MODEL_DIR, "encoder_model.onnx")
DECODER_PATH = os.path.join(MODEL_DIR, "decoder_model.onnx")

print("--- Loading AI Model (Tadabur) ---")
# تحميل المعالج والمقاطع
processor = AutoProcessor.from_pretrained("FaisaI/tadabur-Whisper-Small")
tokenizer = AutoTokenizer.from_pretrained("FaisaI/tadabur-Whisper-Small")

# تحميل المحرك
sess_options = ort.SessionOptions()
encoder_sess = ort.InferenceSession(ENCODER_PATH, sess_options, providers=['CPUExecutionProvider'])
decoder_sess = ort.InferenceSession(DECODER_PATH, sess_options, providers=['CPUExecutionProvider'])

print("✅ Model Loaded Successfully!")

# إعداد الميكروفون
q = queue.Queue()

def callback(indata, frames, time, status):
    if status:
        print(status, file=sys.stderr)
    q.put(indata.copy())

print("\n🎙️  الميكروفون جاهز! ابدأ القراءة الآن...")
print("(اضغط Ctrl+C للإيقاف)\n")

try:
    with sd.InputStream(samplerate=16000, channels=1, callback=callback):
        while True:
            # هنا سنقوم بمعالجة الصوت وتحويله لنص
            # للتبسيط في هذا الاختبار، سنقوم بتجميع الصوت ومعالجته كل 5 ثوانٍ
            audio_data = []
            for _ in range(50): # تقريباً 5 ثوانٍ
                audio_data.append(q.get())
            
            full_audio = np.concatenate(audio_data).flatten()
            
            # تحويل الصوت لمدخلات للنموذج
            input_features = processor(full_audio, sampling_rate=16000, return_tensors="pt").input_features.numpy()
            
            # تشغيل الـ Encoder
            encoder_outputs = encoder_sess.run(None, {"input_features": input_features})[0]
            
            # تشغيل الـ Decoder (مبسط جداً للاختبار)
            # سنقوم بتوليد النص الأساسي
            tokens = [tokenizer.bos_token_id]
            for _ in range(20): # توليد أول 20 كلمة
                decoder_input = np.array([tokens], dtype=np.int64)
                logits = decoder_sess.run(None, {
                    "input_ids": decoder_input,
                    "encoder_hidden_states": encoder_outputs
                })[0]
                
                next_token = np.argmax(logits[0, -1, :])
                tokens.append(next_token)
                if next_token == tokenizer.eos_token_id:
                    break
            
            text = tokenizer.decode(tokens, skip_special_tokens=True)
            if text.strip():
                print(f"📖 التلاوة: {text}")

except KeyboardInterrupt:
    print("\n\nتم إيقاف التجربة. شكراً لك!")
except Exception as e:
    print(f"\n❌ حدث خطأ: {e}")
