import requests
import os
from urllib.parse import urljoin
import time

def download_images(base_url, start_page, end_page, output_folder="tafsir_images"):
    """
    يقوم بتنزيل صور التفسير من موقع tafsir.app
    
    Parameters:
    base_url (str): الرابط الأساسي للصور (مثال: https://tafsir.app/scans/m-qpc-shamarly/)
    start_page (int): رقم الصفحة الأولى
    end_page (int): رقم الصفحة الأخيرة
    output_folder (str): مجلد الحفظ
    """
    
    # إنشاء المجلد إذا لم يكن موجوداً
    if not os.path.exists(output_folder):
        os.makedirs(output_folder)
        print(f"تم إنشاء المجلد: {output_folder}")
    
    # إضافة شريط مائل إذا لم يكن موجوداً
    if not base_url.endswith('/'):
        base_url += '/'
    
    # عداد للصور التي تم تنزيلها بنجاح
    successful_downloads = 0
    
    for page_num in range(start_page, end_page + 1):
        # بناء رابط الصورة
        image_url = f"{base_url}{page_num}.png"
        filename = f"page_{page_num:03d}.png"  # تنسيق الأرقام بثلاث خانات
        filepath = os.path.join(output_folder, filename)
        
        try:
            print(f"جاري تنزيل: {image_url}")
            
            # إرسال طلب HTTP
            response = requests.get(image_url, headers={
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
            }, timeout=30)
            
            # التحقق من نجاح الطلب
            if response.status_code == 200:
                # حفظ الصورة
                with open(filepath, 'wb') as f:
                    f.write(response.content)
                
                print(f"✓ تم حفظ: {filename}")
                successful_downloads += 1
                
            else:
                print(f"✗ خطأ في الصفحة {page_num}: {response.status_code}")
                
        except Exception as e:
            print(f"✗ خطأ في تنزيل الصفحة {page_num}: {str(e)}")
        
        # تأخير بسيط لتجنب حظر الموقع
        time.sleep(0.5)
    
    print(f"\n{'='*50}")
    print(f"تم الانتهاء من عملية التنزيل!")
    print(f"نجح: {successful_downloads} من أصل {end_page - start_page + 1}")
    print(f"المجلد: {os.path.abspath(output_folder)}")

# مثال للاستخدام
if __name__ == "__main__":
    # رابط الملفات كما في المثال
    base_url = "https://tafsir.app/scans/m-qpc-shamarly/"
    
    # تحديد نطاق الصفحات (تعديل حسب الحاجة)
    start_page = 522
    end_page = 604  # غير هذا الرقم حسب عدد الصفحات
    
    # استدعاء الدالة
    download_images(base_url, start_page, end_page, "صور_التفسير")