import sounddevice as sd
import numpy as np
import time

print("\n=== فحص الميكروفون (تشخيص دقيق) ===")
print("الميكروفون الافتراضي المحدد في ويندوز:")
default_device = sd.query_devices(sd.default.device[0], 'input')
print(f"الاسم: {default_device['name']}")
print(f"القنوات: {default_device['max_input_channels']}")
print(f"معدل النقل الافتراضي: {default_device['default_samplerate']}")
print("=====================================\n")

audio_data = []

def callback(indata, frames, time, status):
    if status:
        print(f"⚠️ تحذير الميكروفون: {status}")
    audio_data.append(indata.copy())

print("🎙️ جاري تسجيل الصوت لمدة 3 ثوانٍ... تحدث الآن!")
try:
    with sd.InputStream(samplerate=16000, channels=1, callback=callback):
        time.sleep(3)
        
    if len(audio_data) > 0:
        full_audio = np.concatenate(audio_data).flatten()
        amplitude = np.max(np.abs(full_audio))
        print("\n✅ تم التسجيل بنجاح!")
        print(f"📊 أقصى مستوى للصوت تم التقاطه: {amplitude:.5f}")
        if amplitude < 0.01:
            print("❌ الصوت صامت تماماً أو الميكروفون معطل/مكتوم.")
        else:
            print("🔊 الميكروفون يعمل ويلتقط الصوت بشكل ممتاز!")
    else:
        print("\n❌ لم يتم التقاط أي بيانات صوتية.")
except Exception as e:
    print(f"\n❌ حدث خطأ فادح أثناء محاولة فتح الميكروفون:")
    print(str(e))
